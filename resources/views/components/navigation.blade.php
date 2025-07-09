<nav class="bg-[#1a1a2e] p-4 shadow-md"> {{-- Adjust background color --}}
    <div class="container mx-auto flex justify-between items-center">
        <div class="text-white text-2xl font-bold">Lamablog</div>
        <div class="flex items-center space-x-4">
            <a href="/" class="text-white hover:text-[#e94560]">Home</a>
            <a href="/login" class="text-white hover:text-[#e94560]">Login</a>

            {{-- Conditional display for logged-in user --}}
            @auth {{-- This is a Laravel Blade directive to check if a user is authenticated --}}
            <span class="text-white">Welcome, {{ Auth::user()->name }}!</span>
            <form action="/logout" method="POST" class="inline">
                @csrf
                <button type="submit" class="text-white hover:text-[#e94560]">Logout</button>
            </form>
            @endauth

            {{-- Social Media Icons and Links --}}
            <div class="flex space-x-3 ml-4">
                <a href="https://facebook.com" target="_blank" class="text-white hover:text-[#e94560]">
                    <img src="https://img.icons8.com/ios-filled/24/ffffff/facebook-new.png" alt="Facebook"
                        class="w-6 h-6" />
                </a>
                <a href="https://twitter.com" target="_blank" class="text-white hover:text-[#e94560]">
                    <img src="https://img.icons8.com/ios-filled/24/ffffff/twitter.png" alt="Twitter" class="w-6 h-6" />
                </a>
                <a href="https://instagram.com" target="_blank" class="text-white hover:text-[#e94560]">
                    <img src="https://img.icons8.com/ios-filled/24/ffffff/instagram-new--v1.png" alt="Instagram"
                        class="w-6 h-6" />
                </a>
            </div>
        </div>
    </div>
</nav>