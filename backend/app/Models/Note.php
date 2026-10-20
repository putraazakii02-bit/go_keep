<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class Note extends Model
{
    use HasUuids;

    protected $fillable = [
        'title',
        'content',
        'color',
        'is_pinned',
        'is_archived',
        'is_deleted',
        'reminder_at',
    ];

    protected function casts(): array
    {
        return [
            'is_pinned' => 'boolean',
            'is_archived' => 'boolean',
            'is_deleted' => 'boolean',
            'reminder_at' => 'datetime',
        ];
    }

    public function labels(): BelongsToMany
    {
        return $this->belongsToMany(Label::class, 'note_label');
    }
}
