class CreateAudited < ActiveRecord::Migration[8.0]
  def up
    execute(
      <<~SQL
        -- Create a schema named "audit"
        CREATE SCHEMA audit;
        REVOKE CREATE ON SCHEMA audit FROM public;

        CREATE TABLE audit.logged_actions (
            schema_name TEXT NOT NULL,
            table_name TEXT NOT NULL,
            record_id INTEGER NOT NULL,
            user_name TEXT,
            action_tstamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
            action TEXT NOT NULL CHECK (action IN ('I', 'D', 'U')),
            original_data TEXT,
            new_data TEXT,
            query TEXT
        ) WITH (fillfactor=100);

        REVOKE ALL ON audit.logged_actions FROM public;
        GRANT SELECT ON audit.logged_actions TO public;

      CREATE INDEX logged_actions_schema_table_idx
      ON audit.logged_actions(((schema_name || '.' || table_name)::TEXT));

      CREATE INDEX logged_actions_action_tstamp_idx
      ON audit.logged_actions(action_tstamp);

      CREATE INDEX logged_actions_action_idx
      ON audit.logged_actions(action);

      CREATE OR REPLACE FUNCTION audit.log_current_action() RETURNS trigger AS $$
      DECLARE
          user_name TEXT;
          v_old_data TEXT;
          v_new_data TEXT;
      BEGIN
          user_name := current_setting('app.current_user_id', false);

          IF (TG_OP = 'UPDATE') THEN
              v_old_data := ROW(OLD.*);
              v_new_data := ROW(NEW.*);
              INSERT INTO audit.logged_actions (
                  schema_name, table_name, record_id, user_name, action, original_data, new_data, query
              ) VALUES (
                  TG_TABLE_SCHEMA, TG_TABLE_NAME, NEW.id, user_name, 'U', v_old_data, v_new_data, current_query()
              );
              RETURN NEW;
          ELSIF (TG_OP = 'DELETE') THEN
              v_old_data := ROW(OLD.*);
              INSERT INTO audit.logged_actions (
                  schema_name, table_name, record_id, user_name, action, original_data, query
              ) VALUES (
                  TG_TABLE_SCHEMA, TG_TABLE_NAME, OLD.id, user_name, 'D', v_old_data, current_query()
              );
              RETURN OLD;
          ELSIF (TG_OP = 'INSERT') THEN
              v_new_data := ROW(NEW.*);
              INSERT INTO audit.logged_actions (
                  schema_name, table_name, record_id, user_name, action, new_data, query
              ) VALUES (
                  TG_TABLE_SCHEMA, TG_TABLE_NAME, NEW.id, user_name, 'I', v_new_data, current_query()
              );
              RETURN NEW;
          ELSE
              RAISE WARNING 'Unknown operation: %', TG_OP;
              RETURN NULL;
          END IF;
      END;
      $$ LANGUAGE plpgsql SECURITY DEFINER;

      SQL
    )
  end

  def down

  end
end
