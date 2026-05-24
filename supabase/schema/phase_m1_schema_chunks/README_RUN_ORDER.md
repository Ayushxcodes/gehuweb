# Mock Phase M1 Safe Run Order (One-by-One)

Run in this exact sequence:

1. `phase_m1_mock_schema_chunk_01.sql`
2. `phase_m1_mock_schema_chunk_02.sql`
3. `phase_m1_mock_schema_chunk_03.sql`
4. `phase_m1_mock_schema_chunk_04.sql`
5. `phase_m1_mock_schema_chunk_05.sql`
6. `../phase_m1_chunks/phase_m1_mock_rls_chunk_01.sql`
7. `../phase_m1_chunks/phase_m1_mock_rls_chunk_02.sql`
8. `../phase_m1_chunks/phase_m1_mock_rls_chunk_03.sql`
9. `../phase_m1_mock_verify.sql`

Important:
- Open a fresh SQL tab for each file.
- Clear existing text in the editor before pasting.
- If one step fails, stop and share the exact error.
