import os
path = 'lib/screens/transaction_add_detailed_screen_logic.dart'
c = open(path, 'r', encoding='utf-8').read()
c = c.replace('$_shoppingAvgLookbackDays', '${_TransactionAddDetailedFormState._shoppingAvgLookbackDays}')
c = c.replace('$_draftTtlMs', '${_TransactionAddDetailedFormState._draftTtlMs}')
open(path, 'w', encoding='utf-8').write(c)
