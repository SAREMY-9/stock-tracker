<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Stock;
use Illuminate\Support\Facades\Auth;

class StockController extends Controller
{
    
    public function uploadForm()
    {
        return view('stocks.upload');
    }

    
    public function upload(Request $request)
    {
        $request->validate([
            'file' => 'required|mimes:csv,txt'
        ]);

        $path = $request->file('file')->getRealPath();
        $rows = array_map('str_getcsv', file($path));
        $header = array_map('strtolower', array_map('trim', array_shift($rows)));

        foreach ($rows as $row) {
            if (count($row) >= 3) {
                Stock::create([
                    'name' => trim($row[0]),
                    'price' => (float) $row[1],
                    'date' => date('Y-m-d', strtotime($row[2])),
                    'user_id' => Auth::id(),
                ]);
            }
        }

        return redirect()->route('stocks.chart');
    }



    public function Chart()
{
    // Get all distinct stock names
    $stocks = Stock::select('name')->distinct()->pluck('name');

    $performance = [];

    // Calculate performance (price gain) for each stock
    foreach ($stocks as $stockName) {
        $prices = Stock::where('name', $stockName)
            ->orderBy('date', 'asc')
            ->pluck('price');

        if ($prices->count() > 1) {
            $gain = $prices->last() - $prices->first();
            $performance[$stockName] = round($gain, 2);
        }
    }

    // Sort descending and take top 5
    arsort($performance);
    $top5 = array_slice($performance, 0, 5, true);

    // Prepare chart data
    $labels = array_keys($top5);
    $data = array_values($top5);

    return view('stocks.chart', compact('labels', 'data', 'top5'));
}


  }
