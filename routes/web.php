<?php

use App\Http\Controllers\StockController;
use App\Http\Controllers\ProfileController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/dashboard', function () {
    return view('dashboard');
})->middleware(['auth', 'verified'])->name('dashboard');

Route::middleware('auth')->group(function () {
    Route::get('/profile', [ProfileController::class, 'edit'])->name('profile.edit');
    Route::patch('/profile', [ProfileController::class, 'update'])->name('profile.update');
    Route::delete('/profile', [ProfileController::class, 'destroy'])->name('profile.destroy');
});

Route::middleware(['auth'])->group(function () {
    Route::get('/upload', [StockController::class, 'uploadForm'])->name('stocks.upload');
    Route::post('/upload', [StockController::class, 'upload']);
    Route::get('/chart', [StockController::class, 'chart'])->name('stocks.chart');
});
require __DIR__.'/auth.php';
