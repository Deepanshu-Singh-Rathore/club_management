from django.db import migrations


def add_columns(apps, schema_editor):
    if schema_editor.connection.vendor == 'postgresql':
        schema_editor.execute("""
            ALTER TABLE clubs_event
                ADD COLUMN IF NOT EXISTS status VARCHAR(20) NOT NULL DEFAULT 'upcoming',
                ADD COLUMN IF NOT EXISTS capacity INTEGER NOT NULL DEFAULT 0;
        """)


def reverse_columns(apps, schema_editor):
    if schema_editor.connection.vendor == 'postgresql':
        schema_editor.execute("""
            ALTER TABLE clubs_event
                DROP COLUMN IF EXISTS status,
                DROP COLUMN IF EXISTS capacity;
        """)


class Migration(migrations.Migration):

    dependencies = [
        ('clubs', '0011_clubmessage'),
    ]

    operations = [
        migrations.RunPython(add_columns, reverse_columns),
    ]

