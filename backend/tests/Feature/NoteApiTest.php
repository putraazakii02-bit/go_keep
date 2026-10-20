<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class NoteApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_it_creates_and_updates_a_note_with_labels(): void
    {
        $created = $this->postJson('/api/notes', [
            'title' => 'Belanja',
            'content' => 'Kopi',
            'labels' => ['Pribadi'],
        ])->assertCreated()
            ->assertJsonPath('data.title', 'Belanja')
            ->assertJsonPath('data.labels.0', 'Pribadi');

        $id = $created->json('data.id');
        $this->patchJson("/api/notes/{$id}", [
            'isArchived' => true,
            'labels' => ['Rumah'],
        ])->assertOk()
            ->assertJsonPath('data.isArchived', true)
            ->assertJsonPath('data.labels.0', 'Rumah');

        $this->assertDatabaseHas('notes', [
            'id' => $id,
            'is_archived' => true,
        ]);
    }

    public function test_it_filters_notes_by_view_and_label_search(): void
    {
        $this->postJson('/api/notes', [
            'title' => 'Buku',
            'content' => 'Baca',
            'labels' => ['Kerja'],
        ])->assertCreated();

        $archived = $this->postJson('/api/notes', [
            'title' => 'Arsip',
            'content' => 'Catatan lama',
        ])->assertCreated();
        $this->patchJson('/api/notes/'.$archived->json('data.id'), [
            'isArchived' => true,
        ])->assertOk();

        $this->getJson('/api/notes?view=active&q=Kerja')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.title', 'Buku');
        $this->getJson('/api/notes?view=archived')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.title', 'Arsip');
    }

    public function test_it_imports_existing_notes_idempotently_and_clears_trash(): void
    {
        $legacyNote = [
            'id' => '8a10e482-2d59-4a52-94dd-27d899c62144',
            'title' => 'Catatan lama',
            'content' => 'Dipindahkan',
            'isDeleted' => true,
            'labels' => ['Lokal'],
        ];

        $this->postJson('/api/notes/import', ['notes' => [$legacyNote]])
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $legacyNote['id']);
        $this->postJson('/api/notes/import', ['notes' => [$legacyNote]])
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $legacyNote['id']);
        $this->assertDatabaseCount('notes', 1);

        $this->deleteJson('/api/notes/trash')->assertNoContent();
        $this->assertDatabaseCount('notes', 0);
    }

    public function test_it_validates_note_input(): void
    {
        $this->postJson('/api/notes', [
            'title' => ['not', 'a', 'string'],
        ])->assertUnprocessable()
            ->assertJsonValidationErrors('title');
    }

    public function test_it_stores_and_clears_a_reminder(): void
    {
        $note = $this->postJson('/api/notes', [
            'title' => 'Telepon',
            'content' => 'Hubungi dokter',
        ])->assertCreated();
        $id = $note->json('data.id');
        $reminderAt = now()->addDay()->startOfMinute()->toISOString();

        $this->patchJson("/api/notes/{$id}", ['reminderAt' => $reminderAt])
            ->assertOk()
            ->assertJsonPath('data.reminderAt', $reminderAt);

        $this->patchJson("/api/notes/{$id}", ['reminderAt' => null])
            ->assertOk()
            ->assertJsonPath('data.reminderAt', null);
    }

    public function test_it_can_rename_and_delete_a_label(): void
    {
        $note = $this->postJson('/api/notes', [
            'title' => 'Belanja',
            'content' => 'Beras',
            'labels' => ['Rumah'],
        ])->assertCreated();

        $this->patchJson('/api/labels', [
            'oldName' => 'Rumah',
            'newName' => 'Dapur',
        ])->assertOk()
            ->assertJsonPath('data.0', 'Dapur');

        $this->getJson('/api/notes?label=Dapur')
            ->assertOk()
            ->assertJsonPath('data.0.id', $note->json('data.id'));

        $this->deleteJson('/api/labels?name=Dapur')->assertNoContent();
        $this->getJson('/api/notes')
            ->assertOk()
            ->assertJsonPath('data.0.labels', []);
    }
}
