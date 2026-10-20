<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Label;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class LabelController extends Controller
{
    public function index()
    {
        return response()->json([
            'data' => Label::query()->orderBy('name')->pluck('name'),
        ]);
    }

    public function update(Request $request)
    {
        $data = $request->validate([
            'oldName' => ['required', 'string', 'max:100', 'exists:labels,name'],
            'newName' => [
                'required',
                'string',
                'max:100',
                Rule::unique('labels', 'name')->ignore(
                    Label::query()->where('name', $request->input('oldName'))->value('id'),
                ),
            ],
        ]);

        Label::query()->where('name', $data['oldName'])
            ->update(['name' => $data['newName']]);

        return $this->index();
    }

    public function destroy(Request $request)
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:100', 'exists:labels,name'],
        ]);

        DB::transaction(function () use ($data): void {
            $label = Label::query()->where('name', $data['name'])->firstOrFail();
            $label->notes()->detach();
            $label->delete();
        });

        return response()->noContent();
    }
}
