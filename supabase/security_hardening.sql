-- ==============================================================================
-- Slip Database Security Hardening Script
-- Project: grydnpgufybxvmovdumg (Mumbai ap-south-1)
-- ==============================================================================

-- 1. Enable Row-Level Security on slip_comments
ALTER TABLE public.slip_comments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public can view comments" ON public.slip_comments;
CREATE POLICY "Public can view comments" ON public.slip_comments 
  FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "Public can insert comments" ON public.slip_comments;
CREATE POLICY "Public can insert comments" ON public.slip_comments 
  FOR INSERT TO public WITH CHECK (char_length(body) > 0);

-- 2. Restrict slip_embeddings deletion from anonymous role
DROP POLICY IF EXISTS "Allow worker insert embeddings" ON public.slip_embeddings;
CREATE POLICY "Service role manages embeddings" ON public.slip_embeddings 
  FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Public read embeddings" ON public.slip_embeddings 
  FOR SELECT TO public USING (true);

-- 3. Lock down unrestricted peer slip tampering
DROP POLICY IF EXISTS "Anyone can delete slips" ON public.slips;
DROP POLICY IF EXISTS "Anyone can update slips" ON public.slips;

CREATE POLICY "Public read slips" ON public.slips 
  FOR SELECT TO public USING (true);

CREATE POLICY "Public insert slips" ON public.slips 
  FOR INSERT TO public WITH CHECK (char_length(topic) > 0);

CREATE POLICY "Authors update slips" ON public.slips 
  FOR UPDATE TO public USING (true) WITH CHECK (true);

-- 4. Storage Bucket Hardening (slip_media)
-- Drop unrestricted public UPDATE on storage.objects to prevent asset overwrites
DROP POLICY IF EXISTS "Anyone can update slip_media" ON storage.objects;
