ALTER TABLE public.user_preferences 
ADD COLUMN IF NOT EXISTS sms_notifications BOOLEAN DEFAULT false;