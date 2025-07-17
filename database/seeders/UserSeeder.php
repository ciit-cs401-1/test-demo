<?php

namespace Database\Seeders;

use App\Models\Role;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Create users first and ensure we get a Collection
        $users = collect(User::factory(env('MAX_USER_SEED'))->create());

        // Get the roles as models
        $adminRole = Role::where('role_name', 'A')->first();
        $contributorRole = Role::where('role_name', 'C')->first();
        $subscriberRole = Role::where('role_name', 'S')->first();

        // Assign all roles to a random user (admin)
        $adminUser = $users->random();
        $adminUser->roles()->attach([$adminRole->id, $contributorRole->id, $subscriberRole->id]);

        // Assign random roles to other users
        foreach ($users as $user) {
            if ($user->id !== $adminUser->id) {
                $roleIds = collect([$contributorRole->id, $subscriberRole->id])
                    ->shuffle()
                    ->take(rand(1, 2))
                    ->all();
                $user->roles()->attach($roleIds);
            }
        }
    }
}
