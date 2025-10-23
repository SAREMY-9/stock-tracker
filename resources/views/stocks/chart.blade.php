<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Top 5 Stock Performers</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 40px auto;
            text-align: center;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 30px;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 12px;
        }
        th {
            background-color: #4CAF50;
            color: white;
        }
        tr:nth-child(even) { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h2>📊 Top 5 Stock Performers</h2>

    <canvas id="stockChart" height="100"></canvas>

    <script>
        const ctx = document.getElementById('stockChart');
        new Chart(ctx, {
            type: 'bar',
            data: {
                labels: @json($labels),
                datasets: [{
                    label: 'Price Gain',
                    data: @json($data),
                    borderWidth: 1,
                    backgroundColor: [
                        '#4CAF50', '#2196F3', '#FF9800', '#E91E63', '#9C27B0'
                    ],
                }]
            },
            options: {
                scales: {
                    y: { beginAtZero: true }
                },
                plugins: {
                    legend: { display: false },
                    title: {
                        display: true,
                        text: 'Top 5 Stocks by Price Gain'
                    }
                }
            }
        });
    </script>

    <h3 style="margin-top: 40px;">🏆 Top 5 Performers List</h3>
    <table>
        <thead>
            <tr>
                <th>Rank</th>
                <th>Stock Name</th>
                <th>Price Gain</th>
            </tr>
        </thead>
        <tbody>
            @foreach ($top5 as $stock => $gain)
                <tr>
                    <td>{{ $loop->iteration }}</td>
                    <td>{{ $stock }}</td>
                    <td>{{ $gain }}</td>
                </tr>
            @endforeach
        </tbody>
    </table>
</body>
</html>
