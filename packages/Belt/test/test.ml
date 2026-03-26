let () =
  Alcotest.run "Belt"
    (Test_Belt_Int.suites @ Test_Belt_Float.suites @ Test_Belt_Option.suites @ Test_Belt_Result.suites
   @ Test_Belt_Array.suites @ Test_Belt_List.suites @ Test_Belt_Map.suites @ Test_Belt_Map_Dict.suites
   @ Test_Belt_Map_Int.suites @ Test_Belt_Map_String.suites @ Test_Belt_Set.suites @ Test_Belt_Set_Dict.suites
   @ Test_Belt_Set_Int.suites @ Test_Belt_Set_String.suites @ Test_Belt_SortArray.suites
   @ Test_Belt_SortArray_Int.suites @ Test_Belt_SortArray_String.suites @ Test_Belt_MutableMap.suites
   @ Test_Belt_MutableMap_Int.suites @ Test_Belt_MutableMap_String.suites @ Test_Belt_MutableSet.suites
   @ Test_Belt_MutableSet_Int.suites @ Test_Belt_MutableSet_String.suites @ Test_Belt_HashMap.suites
   @ Test_Belt_HashMap_Int.suites @ Test_Belt_HashMap_String.suites @ Test_Belt_HashSet_Int.suites
   @ Test_Belt_HashSet_String.suites @ Test_Belt_MutableQueue.suites @ Test_Belt_MutableStack.suites)
