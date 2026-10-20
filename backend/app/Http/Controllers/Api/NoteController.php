<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\NoteResource;
use App\Models\Label;
use App\Models\Note;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class NoteController extends Controller
{
    public function index(Request $request)
    {
        $filters = $request->validate([
            'view' => ['sometimes', Rule::in(['all', 'active', 'archived', 'trash'])],
            'q' => ['sometimes', 'string', 'max:255'],
            'label' => ['sometimes', 'string', 'max:100'],
        ]);

        $query = Note::query()->with('labels');

        match ($filters['view'] ?? 'all') {
            'active' => $query->where('is_archived', false)->where('is_deleted', false),
            'archived' => $query->where('is_archived', true)->where('is_deleted', false),
            'trash' => $query->where('is_deleted', true),
            default => null,
        };

        if (isset($filters['q'])) {
            $search = $filters['q'];
            $query->where(function (Builder $query) use ($search): void {
                $query->where('title', 'like', "%{$search}%")
                    ->orWhere('content', 'like', "%{$search}%")
                    ->orWhereHas('labels', fn (Builder $labels) => $labels->where('name', 'like', "%{$search}%"));
            });
        }

        if (isset($filters['label'])) {
            $label = $filters['label'];
            $query->whereHas('labels', fn (Builder $labels) => $labels->where('name', $label));
        }

        $notes = $query->orderByDesc('is_pinned')->orderByDesc('updated_at')->get();

        return NoteResource::collection($notes);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'title' => ['required_without:content', 'nullable', 'string', 'max:255'],
            'content' => ['required_without:title', 'nullable', 'string'],
            'color' => ['nullable', 'string', 'max:16'],
            'isPinned' => ['sometimes', 'boolean'],
            'isArchived' => ['sometimes', 'boolean'],
            'isDeleted' => ['sometimes', 'boolean'],
            'reminderAt' => ['sometimes', 'nullable', 'date'],
            'labels' => ['sometimes', 'array', 'max:50'],
            'labels.*' => ['required', 'string', 'max:100', 'distinct'],
        ]);

        $labels = $data['labels'] ?? [];
        $note = DB::transaction(function () use ($data, $labels): Note {
            $attributes = $this->attributesFrom($data);
            $attributes['title'] ??= '';
            $attributes['content'] ??= '';
            $note = Note::create($attributes);
            $this->syncLabels($note, $labels);

            return $note->load('labels');
        });

        return (new NoteResource($note))->response()->setStatusCode(201);
    }

    public function import(Request $request)
    {
        $data = $request->validate([
            'notes' => ['required', 'array', 'max:1000'],
            'notes.*.id' => ['required', 'uuid'],
            'notes.*.title' => ['nullable', 'string', 'max:255'],
            'notes.*.content' => ['nullable', 'string'],
            'notes.*.color' => ['nullable', 'string', 'max:16'],
            'notes.*.isPinned' => ['sometimes', 'boolean'],
            'notes.*.isArchived' => ['sometimes', 'boolean'],
            'notes.*.isDeleted' => ['sometimes', 'boolean'],
            'notes.*.reminderAt' => ['sometimes', 'nullable', 'date'],
            'notes.*.labels' => ['sometimes', 'array', 'max:50'],
            'notes.*.labels.*' => ['required', 'string', 'max:100', 'distinct'],
        ]);

        $notes = DB::transaction(function () use ($data) {
            return collect($data['notes'])->map(function (array $item): Note {
                $attributes = $this->attributesFrom($item);
                $attributes['title'] ??= '';
                $attributes['content'] ??= '';
                $note = Note::firstOrNew(['id' => $item['id']]);
                $note->id = $item['id'];
                $note->fill($attributes);
                $note->save();
                $this->syncLabels($note, $item['labels'] ?? []);

                return $note->load('labels');
            });
        });

        return NoteResource::collection($notes);
    }

    public function show(Note $note): NoteResource
    {
        return new NoteResource($note->load('labels'));
    }

    public function update(Request $request, Note $note): NoteResource
    {
        $data = $request->validate([
            'title' => ['sometimes', 'nullable', 'string', 'max:255'],
            'content' => ['sometimes', 'nullable', 'string'],
            'color' => ['sometimes', 'nullable', 'string', 'max:16'],
            'isPinned' => ['sometimes', 'boolean'],
            'isArchived' => ['sometimes', 'boolean'],
            'isDeleted' => ['sometimes', 'boolean'],
            'reminderAt' => ['sometimes', 'nullable', 'date'],
            'labels' => ['sometimes', 'array', 'max:50'],
            'labels.*' => ['required', 'string', 'max:100', 'distinct'],
        ]);

        DB::transaction(function () use ($data, $note): void {
            $note->fill($this->attributesFrom($data));
            $note->save();

            if (array_key_exists('labels', $data)) {
                $this->syncLabels($note, $data['labels']);
            }
        });

        return new NoteResource($note->fresh()->load('labels'));
    }

    public function destroy(Note $note)
    {
        $note->delete();

        return response()->noContent();
    }

    public function emptyTrash()
    {
        Note::query()->where('is_deleted', true)->delete();

        return response()->noContent();
    }

    private function attributesFrom(array $data): array
    {
        $attributes = [];
        foreach ([
            'title' => 'title',
            'content' => 'content',
            'color' => 'color',
            'isPinned' => 'is_pinned',
            'isArchived' => 'is_archived',
            'isDeleted' => 'is_deleted',
            'reminderAt' => 'reminder_at',
        ] as $input => $column) {
            if (array_key_exists($input, $data)) {
                $attributes[$column] = $data[$input];
            }
        }

        return $attributes;
    }

    private function syncLabels(Note $note, array $names): void
    {
        $labelIds = [];
        foreach (array_unique($names) as $name) {
            $labelIds[] = Label::firstOrCreate(['name' => $name])->id;
        }

        $note->labels()->sync($labelIds);
    }
}
