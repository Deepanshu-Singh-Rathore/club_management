from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('clubs', '0011_clubmessage'),
    ]

    operations = [
        migrations.RunSQL(
            sql="""
                ALTER TABLE clubs_event
                    ADD COLUMN IF NOT EXISTS status VARCHAR(20) NOT NULL DEFAULT 'upcoming',
                    ADD COLUMN IF NOT EXISTS capacity INTEGER NOT NULL DEFAULT 0;
            """,
            reverse_sql="""
                ALTER TABLE clubs_event
                    DROP COLUMN IF EXISTS status,
                    DROP COLUMN IF EXISTS capacity;
            """,
        ),
    ]
