<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class NoteResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'content' => $this->content,
            'color' => $this->color,
            'isPinned' => $this->is_pinned,
            'isArchived' => $this->is_archived,
            'isDeleted' => $this->is_deleted,
            'reminderAt' => $this->reminder_at?->toISOString(),
            'labels' => $this->whenLoaded(
                'labels',
                fn () => $this->labels->pluck('name')->values(),
            ),
            'createdAt' => $this->created_at?->toISOString(),
            'updatedAt' => $this->updated_at?->toISOString(),
        ];
    }
}
