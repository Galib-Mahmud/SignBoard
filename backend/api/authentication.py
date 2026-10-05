from rest_framework.authentication import TokenAuthentication
from rest_framework.authtoken.models import Token
from rest_framework import exceptions

class LenientTokenAuthentication(TokenAuthentication):
    """
    Tolerant Token Authentication.
    If an invalid or expired token is provided on a public endpoint,
    instead of throwing AuthenticationFailed (HTTP 401), it gracefully
    treats the user as AnonymousUser (None) so public browsing works seamlessly.
    For protected views, permissions (e.g. IsAuthenticated) will handle access.
    """
    def authenticate_credentials(self, key):
        model = self.get_model()
        try:
            token = model.objects.select_related('user').get(key=key)
        except model.DoesNotExist:
            # Return None instead of raising AuthenticationFailed
            # This allows unauthenticated / public browsing when client has a stale token from another environment
            return None

        if not token.user.is_active:
            return None

        return (token.user, token)
