@extends('layouts.master')

@section('title', 'Login')

@section('content')
<div class="flex items-center justify-center min-h-screen">
    <div class="bg-[#24263b] p-8 rounded-lg shadow-lg w-full max-w-md"> {{-- Adjust background color --}}
        <h2 class="text-3xl font-bold mb-6 text-center text-white">Login</h2>
        <form>
            <div class="mb-4">
                <label for="email" class="block text-white text-sm font-bold mb-2">Email:</label>
                <input type="email" id="email" name="email"
                    class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline bg-[#3a3f5c]"
                    placeholder="Enter your email"> {{-- Adjust input background --}}
            </div>
            <div class="mb-6">
                <label for="password" class="block text-white text-sm font-bold mb-2">Password:</label>
                <input type="password" id="password" name="password"
                    class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 mb-3 leading-tight focus:outline-none focus:shadow-outline bg-[#3a3f5c]"
                    placeholder="Enter your password"> {{-- Adjust input background --}}
            </div>
            <div class="flex items-center justify-between">
                <button type="submit"
                    class="bg-[#e94560] hover:bg-[#c2364e] text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline">
                    Login
                </button>
                <a class="inline-block align-baseline font-bold text-sm text-[#e94560] hover:text-[#c2364e]"
                    href="/register">
                    Don't have an account? Register
                </a>
            </div>
        </form>
    </div>
</div>
@endsection