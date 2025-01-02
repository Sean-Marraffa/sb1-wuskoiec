@@ .. @@
 CREATE OR REPLACE FUNCTION check_user_role(
     target_business_id UUID,
     required_role TEXT,
-    authenticated_user_id UUID
+    authenticated_user_id UUID DEFAULT auth.uid()
 ) RETURNS BOOLEAN
 LANGUAGE plpgsql
 AS $$
-DECLARE
-    has_role BOOLEAN;
 BEGIN
-    SELECT EXISTS (
+    RETURN EXISTS (
         SELECT 1
         FROM business_users bu
         WHERE bu.business_id = target_business_id
           AND bu.user_id = authenticated_user_id
           AND bu.role = required_role
-    ) INTO has_role;
-
-    RETURN has_role;
+        LIMIT 1
+    );
 END;
 $$;

@@ .. @@
 CREATE POLICY "allow_business_profile_updates"
 ON "public"."businesses"
 FOR ALL
-TO authenticated
-USING (
-    check_user_role(id, 'Account Owner'::TEXT, auth.uid())
-)
-WITH CHECK (
-    check_user_role(id, 'Account Owner'::TEXT, auth.uid())
+TO authenticated 
+USING (
+    id IN (
+        SELECT business_id 
+        FROM business_users 
+        WHERE user_id = auth.uid() 
+        AND role = 'Account Owner'
+    )
+)
+WITH CHECK (
+    id IN (
+        SELECT business_id 
+        FROM business_users 
+        WHERE user_id = auth.uid() 
+        AND role = 'Account Owner'
+    )
 );