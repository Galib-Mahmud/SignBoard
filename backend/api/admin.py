from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User, Category, Post, SavedPost

@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ('username', 'email', 'first_name', 'last_name', 'is_staff', 'subscription_tier', 'created_at')
    list_filter = ('is_staff', 'is_superuser', 'is_active', 'subscription_tier')
    search_fields = ('username', 'email', 'first_name', 'last_name', 'google_id')
    ordering = ('-date_joined',)


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'icon', 'order', 'created_at')
    search_fields = ('id', 'name')
    ordering = ('order', 'name')


@admin.register(Post)
class PostAdmin(admin.ModelAdmin):
    list_display = ('title', 'category', 'user', 'city', 'contact_whatsapp', 'views_count', 'is_active', 'created_at')
    list_filter = ('category', 'is_active', 'city', 'created_at')
    search_fields = ('title', 'description', 'city', 'address', 'contact_whatsapp', 'user__username', 'user__email')
    ordering = ('-created_at',)
    actions = ['delete_selected_posts', 'deactivate_posts', 'activate_posts']

    @admin.action(description="Soft delete / Deactivate selected posts")
    def deactivate_posts(self, request, queryset):
        queryset.update(is_active=False)

    @admin.action(description="Reactivate selected posts")
    def activate_posts(self, request, queryset):
        queryset.update(is_active=True)


@admin.register(SavedPost)
class SavedPostAdmin(admin.ModelAdmin):
    list_display = ('user', 'post', 'created_at')
    search_fields = ('user__username', 'user__email', 'post__title')
    list_filter = ('created_at',)

