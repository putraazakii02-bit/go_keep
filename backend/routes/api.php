<?php

use App\Http\Controllers\Api\LabelController;
use App\Http\Controllers\Api\NoteController;
use Illuminate\Support\Facades\Route;

Route::get('notes', [NoteController::class, 'index']);
Route::get('labels', [LabelController::class, 'index']);
Route::patch('labels', [LabelController::class, 'update']);
Route::delete('labels', [LabelController::class, 'destroy']);
Route::post('notes', [NoteController::class, 'store']);
Route::post('notes/import', [NoteController::class, 'import']);
Route::delete('notes/trash', [NoteController::class, 'emptyTrash']);
Route::get('notes/{note}', [NoteController::class, 'show']);
Route::put('notes/{note}', [NoteController::class, 'update']);
Route::patch('notes/{note}', [NoteController::class, 'update']);
Route::delete('notes/{note}', [NoteController::class, 'destroy']);
