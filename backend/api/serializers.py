from rest_framework import serializers
from .models import User, Category, Post, SavedPost
import math

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            'id', 'username', 'email', 'first_name', 'last_name',
            'avatar_url', 'phone_number', 'whatsapp_number',
            'subscription_tier', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']


class CategorySerializer(serializers.ModelSerializer):
    posts_count = serializers.IntegerField(read_only=True, default=0)

    class Meta:
        model = Category
        fields = ['id', 'name', 'icon', 'order', 'fields_schema', 'posts_count']


class PostSerializer(serializers.ModelSerializer):
    category_name = serializers.CharField(source='category.name', read_only=True)
    category_id = serializers.CharField(source='category.id', read_only=True)
    user_name = serializers.SerializerMethodField()
    user_avatar = serializers.CharField(source='user.avatar_url', read_only=True)
    is_saved = serializers.SerializerMethodField()
    distance_km = serializers.SerializerMethodField()

    class Meta:
        model = Post
        fields = [
            'id', 'title', 'description', 'category', 'category_id', 'category_name',
            'contact_whatsapp', 'structured_data', 'latitude', 'longitude',
            'address', 'city', 'distance_km', 'is_saved', 'views_count',
            'user_name', 'user_avatar', 'created_at'
        ]
        read_only_fields = ['id', 'views_count', 'created_at']

    def get_user_name(self, obj):
        name = f"{obj.user.first_name} {obj.user.last_name}".strip()
        return name if name else obj.user.username

    def get_is_saved(self, obj):
        request = self.context.get('request')
        if not request or not request.user or not request.user.is_authenticated:
            return False
        # If pre-annotated or checked
        if hasattr(obj, '_is_saved'):
            return obj._is_saved
        return SavedPost.objects.filter(user=request.user, post=obj).exists()

    def get_distance_km(self, obj):
        # If pre-calculated in queryset annotation
        if hasattr(obj, 'distance'):
            return round(obj.distance, 1)
        
        # Calculate on the fly if user_lat and user_lng were provided in query params
        request = self.context.get('request')
        if not request:
            return None
        try:
            u_lat = float(request.query_params.get('latitude'))
            u_lng = float(request.query_params.get('longitude'))
            return self._calculate_haversine(u_lat, u_lng, obj.latitude, obj.longitude)
        except (TypeError, ValueError):
            return None

    @staticmethod
    def _calculate_haversine(lat1, lon1, lat2, lon2):
        r = 6371.0 # Earth radius in kilometers
        d_lat = math.radians(lat2 - lat1)
        d_lon = math.radians(lon2 - lon1)
        a = (math.sin(d_lat / 2) ** 2 +
             math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) *
             math.sin(d_lon / 2) ** 2)
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
        return round(r * c, 1)


class PostCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Post
        fields = [
            'id', 'category', 'title', 'description', 'contact_whatsapp',
            'structured_data', 'latitude', 'longitude', 'address', 'city'
        ]
        read_only_fields = ['id']

    def validate_contact_whatsapp(self, value):
        cleaned = value.replace('+', '').replace(' ', '').replace('-', '')
        if not cleaned.isdigit() or len(cleaned) < 8:
            raise serializers.ValidationError("Enter a valid WhatsApp phone number with country code.")
        return cleaned


class SavedPostSerializer(serializers.ModelSerializer):
    post = PostSerializer(read_only=True)

    class Meta:
        model = SavedPost
        fields = ['id', 'post', 'created_at']
