from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion
import uuid


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ('clubs', '0002_event_image_url'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            state_operations=[
                migrations.CreateModel(
                    name='Event',
                    fields=[
                        ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                        ('title', models.CharField(max_length=255)),
                        ('description', models.TextField(blank=True)),
                        ('event_date', models.DateTimeField()),
                        ('created_at', models.DateTimeField(auto_now_add=True)),
                        ('club', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='events', to='clubs.club')),
                        ('created_by', models.ForeignKey(null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='events_created', to=settings.AUTH_USER_MODEL)),
                    ],
                    options={
                        'db_table': 'events',
                        'ordering': ['event_date'],
                    },
                ),
            ],
            database_operations=[],
        ),
        migrations.CreateModel(
            name='EventRegistration',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('status', models.CharField(choices=[('registered', 'Registered'), ('attended', 'Attended')], default='registered', max_length=20)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('event', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='registrations', to='events.event')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='event_registrations', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'db_table': 'event_registrations',
                'ordering': ['-created_at'],
                'unique_together': {('user', 'event')},
            },
        ),
    ]
