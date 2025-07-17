<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\Post;
use App\Models\User;
use Illuminate\Database\Seeder;

class PostSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Check for MAX_USER_SEED in env first, then fallback to config
        $max_seed = env('MAX_POST_SEED');
        if ($max_seed == null) {
            $max_seed = config('seeder.max_post_seed');;
        }

        $users = User::all();
        $categories = Category::all();

        Post::factory($max_seed)
            ->make()
            ->each(function ($post) use ($users, $categories) {
                $user = $users->random();
                $post->user_id = $user->id;
                $post->publication_date = fake()->optional()->dateTime();
                if ($post->publication_date) {
                    $post->views_count = fake()->numberBetween(1, 50000);
                }
                $post->save();

                $categoryCount = $categories->count();
                $numberOfCategoriesToSelect = min(5, $categoryCount);

                // Handle the case where there are no categories.
                if ($categoryCount > 0) {
                    $randomCategories = $categories->random(rand(1, $numberOfCategoriesToSelect))
                        ->pluck('id')->toArray();
                } else {
                    $randomCategories = []; //set empty if no categories found.
                }
                $post->categories()->attach($randomCategories);
            });

        $randomPost = Post::where('publication_date', '!=', null)->inRandomOrder()->first();

        if ($randomPost) {
            $randomPost->update(['featured_post' => true]);
            echo "Marked post ID: {$randomPost->id} as featured.\n";
        } else {
            echo "No posts found to mark as featured. Please ensure posts are created first.\n";
        }
    }
}
