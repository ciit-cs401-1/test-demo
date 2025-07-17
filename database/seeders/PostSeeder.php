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

        $users = User::all();
        $categories = Category::all();

        Post::factory(env('MAX_POST_SEED'))
            ->make()
            ->each(function ($post) use ($users, $categories) {
                $user = $users->count() ? $users->random() : null;
                if ($user) {
                    $post->user_id = $user->id;
                }
                $post->publication_date = fake()->optional()->dateTime();
                if ($post->publication_date) {
                    $post->views_count = fake()->numberBetween(1, 50000);
                }
                $post->save();

                $categoryCount = $categories->count();
                $numberOfCategoriesToSelect = min(5, $categoryCount);

                // Handle the case where there are no categories.
                if ($categoryCount > 0) {
                    $randomCategories = $categories->random(rand(1, $numberOfCategoriesToSelect));
                    // If only one category is returned, wrap in array
                    if ($randomCategories instanceof \Illuminate\Database\Eloquent\Collection) {
                        $randomCategories = $randomCategories->pluck('id')->toArray();
                    } else {
                        $randomCategories = [$randomCategories->id];
                    }
                } else {
                    $randomCategories = [];
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
