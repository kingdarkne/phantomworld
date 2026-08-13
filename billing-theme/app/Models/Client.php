<?php

namespace App\Models;

use App\Notifications\ResetPasswordNotification;
use Illuminate\Auth\Authenticatable;
use Illuminate\Auth\MustVerifyEmail;
use Illuminate\Auth\Passwords\CanResetPassword;
use Illuminate\Contracts\Auth\Access\Authorizable as AuthorizableContract;
use Illuminate\Contracts\Auth\Authenticatable as AuthenticatableContract;
use Illuminate\Contracts\Auth\CanResetPassword as CanResetPasswordContract;
use Illuminate\Contracts\Auth\MustVerifyEmail as MustVerifyEmailContract;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Foundation\Auth\Access\Authorizable;
use Illuminate\Notifications\Notifiable;

class Client extends Model implements
    AuthenticatableContract,
    AuthorizableContract,
    CanResetPasswordContract,
    MustVerifyEmailContract
{
    use Authenticatable, Authorizable, CanResetPassword, MustVerifyEmail, Notifiable;

    protected $fillable = [
        'email',
        'first_name',
        'last_name',
        'email_verified_at',
        'user_id',
        'password',
        'referer_id',
        'credit',
        'clicks',
        'sign_ups',
        'purchases',
        'commissions',
        'currency',
        'country',
        'timezone',
        'language',
        'auto_renew',
        'is_active',
        // is_admin is intentionally NOT fillable — only set by operators in DB/admin UI
    ];

    protected $hidden = ['remember_token'];

    public function getDisplayNameAttribute(): string
    {
        return \App\Support\CustomerName::greetingFor($this) ?: 'there';
    }

    public function sendPasswordResetNotification($token)
    {
        $this->notify(new ResetPasswordNotification($token));
    }
}
