#\!/bin/bash

# Script to reset admin password for Pterodactyl panel
echo "Resetting admin password to 'admin123'..."

docker-compose exec panel php artisan tinker --execute="
\$user = Pterodactyl\\Models\\User::where('email', 'admin@example.com')->first();
if (\$user) {
    \$user->password = Hash::make('admin123');
    \$user->save();
    echo 'Password successfully reset for admin@example.com';
} else {
    echo 'Admin user not found';
}
"

echo ""
echo "Admin login credentials:"
echo "Email: admin@example.com"
echo "Password: admin123"
echo ""
echo "Access the panel at: http://localhost"
