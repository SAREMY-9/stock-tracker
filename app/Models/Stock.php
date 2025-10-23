<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Stock extends Model
{
    //

    protected $fillable = [
    'name',
    'price',
    'date',
    'user_id',
    ];
}
