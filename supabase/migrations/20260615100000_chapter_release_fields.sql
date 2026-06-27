-- Chapter release scheduling (idempotent; columns may already exist in cloud)
ALTER TABLE public."Chapter"
  ADD COLUMN IF NOT EXISTS is_released boolean NOT NULL DEFAULT false;

ALTER TABLE public."Chapter"
  ADD COLUMN IF NOT EXISTS release_date date NULL;
