<script lang="ts">
    import type { NavPage } from "$lib";

    export let navPage: NavPage;
</script>

<div class="nav-container mb-3">
    <nav class="nav nav-pills">
        <a
            class="nav-link d-flex align-items-center gap-1"
            class:active={navPage === "home"}
            href="/"
        >
            <i class="bi bi-house"></i> Home
        </a>
        <a
            class="nav-link d-flex align-items-center gap-1"
            class:active={navPage === "players"}
            href="/players"
        >
            <i class="bi bi-person"></i> Players
        </a>
        <a
            class="nav-link d-flex align-items-center gap-1"
            class:active={navPage === "history"}
            href="/history"
        >
            <i class="bi bi-database"></i> Games
        </a>
    </nav>
</div>

<style>
    .nav-container {
        background-color: white;
        border-radius: 8px;
        padding: 10px;
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
        border: 1px solid #eaeaea;
    }

    .nav-pills .nav-link {
        color: #495057;
        border-radius: 4px;
        padding: 8px 16px;
        transition: all 0.2s ease;
    }

    .nav-pills .nav-link:hover:not(.active) {
        background-color: #f8f9fa;
    }

    .nav-pills .nav-link.active {
        background-color: #0d6efd;
        color: white;
    }

    @media (max-width: 576px) {
        .nav-pills {
            display: flex;
            justify-content: space-between;
            width: 100%;
        }

        .nav-pills .nav-link {
            padding: 6px 10px;
            font-size: 0.9rem;
        }
    }
</style>
