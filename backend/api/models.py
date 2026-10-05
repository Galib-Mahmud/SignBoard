import uuid
from django.db import models
from django.contrib.auth.models import AbstractUser

class User(AbstractUser):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    google_id = models.CharField(max_length=255, unique=True, null=True, blank=True, db_index=True)
    avatar_url = models.URLField(max_length=1000, null=True, blank=True)
    phone_number = models.CharField(max_length=32, null=True, blank=True)
    whatsapp_number = models.CharField(max_length=32, null=True, blank=True)
    subscription_tier = models.CharField(max_length=32, default='free') # 'free', 'pro', 'business'
    subscription_active_until = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        indexes = [
            models.Index(fields=['email']),
            models.Index(fields=['google_id']),
        ]

    def __str__(self):
        return self.email or self.username


class Category(models.Model):
    id = models.CharField(max_length=64, primary_key=True) # e.g. 'tutoring', 'teachers', 'used-products'
    name = models.CharField(max_length=120)
    icon = models.CharField(max_length=64, default='category')
    order = models.IntegerField(default=0)
    # Schema defining standard category-specific structured input fields
    # Example: [{"id": "subject", "label": "Subject", "type": "text", "required": true}]
    fields_schema = models.JSONField(default=list, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['order', 'name']
        verbose_name_plural = 'Categories'

    def __str__(self):
        return self.name


class Post(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='posts')
    category = models.ForeignKey(Category, on_delete=models.PROTECT, related_name='posts', db_index=True)
    
    title = models.CharField(max_length=255, db_index=True)
    description = models.TextField(blank=True, default='')
    contact_whatsapp = models.CharField(max_length=32, help_text='WhatsApp phone number with country code')
    
    # Specific standard structured data input by user (no images, pure structured parameters)
    # e.g., price, rent_fee, experience, room_count, condition, vehicle_model, etc.
    structured_data = models.JSONField(default=dict, blank=True)
    
    # Geolocation fields
    latitude = models.FloatField(db_index=True)
    longitude = models.FloatField(db_index=True)
    address = models.CharField(max_length=300, blank=True, default='')
    city = models.CharField(max_length=100, blank=True, default='', db_index=True)
    
    views_count = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            # High scale indexes for 1M+ posts query performance:
            models.Index(fields=['is_active', '-created_at']),
            models.Index(fields=['category', 'is_active', '-created_at']),
            models.Index(fields=['latitude', 'longitude']),
            models.Index(fields=['user', '-created_at']),
        ]

    def __str__(self):
        return f"{self.title} ({self.category.name})"


class SavedPost(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='saved_posts')
    post = models.ForeignKey(Post, on_delete=models.CASCADE, related_name='saved_by_users')
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        ordering = ['-created_at']
        unique_together = ('user', 'post')
        indexes = [
            models.Index(fields=['user', '-created_at']),
        ]

    def __str__(self):
        return f"{self.user} saved {self.post_id}"
