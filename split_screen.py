
import re
with open('lib/screens/transaction_add_detailed_screen.dart', 'r', encoding='utf-8') as f: text = f.read()
ui_methods = ['_buildStoreOrBuyerField', '_buildInlineHeader', '_buildSaveButtons', '_buildMemoField', '_buildPaymentField', '_buildSavingsAllocationSelector', '_buildSavingsDateField', '_buildCategorySection', '_buildDescriptionInput', '_buildExpenseFields', '_buildRefundFields', '_buildSavingsFields', '_buildIncomeFields', '_buildReceiptScanButton', '_buildDateSection', '_buildAmountSection', '_buildTagsSection']
logic_methods = ['_saveTransaction', 'openShoppingCartPicker', '_predictCategoryWithAI', '_loadDraftIfRecent', '_handleDescriptionChanged', '_updateAmount', '_applyIncomeDefaultCategory', 'triggerAutoSubmit', 'promptRevertToInitial']

def extract_method(source, md):
    m = re.search(r'(\n  (?:Widget|void|Future<.*?>|String|bool|List<.*?>|Map<.*?>)[ \n]?[^\(]*?' + md + r'\s*\(.*?\)\s*(?:async\s*)?\{)', source)
    if not m: return None, source
    s = m.start(1)
    b = 0
    is_str = False
    sc = ''
    esc = False
    fnd = False
    e = -1
    for i in range(s, len(source)):
        c = source[i]
        if esc:
            esc = False
            continue
        if c == chr(92):
            esc = True
            continue
        if is_str:
            if c == sc:
                is_str = False
            continue
        if c in [chr(39), chr(34)]:
            is_str = True
            sc = c
            continue
        if c == '{':
            b += 1
            fnd = True
        elif c == '}':
            b -= 1
        if fnd and b == 0:
            e = i
            break
    if e != -1: return source[s:e+1], source[:s] + source[e+1:]
    return None, source

eu = []
el = []
for m in ui_methods:
    x, text = extract_method(text, m)
    if x: eu.append(x.strip())
for m in logic_methods:
    x, text = extract_method(text, m)
    if x: el.append(x.strip())

ins = text.find('class _TransactionAddDetailedScreenState')
ins = text.rfind(chr(10), 0, ins)
p1 = chr(10) + 'part ' + chr(39) + 'transaction_add_detailed_screen_ui.dart' + chr(39) + ';'
p2 = chr(10) + 'part ' + chr(39) + 'transaction_add_detailed_screen_logic.dart' + chr(39) + ';' + chr(10)
if 'transaction_add_detailed_screen_ui.dart' not in text:
    text = text[:ins] + p1 + p2 + text[ins:]

with open('lib/screens/transaction_add_detailed_screen.dart', 'w', encoding='utf-8') as f:
    f.write(text)

c_ui = 'part of ' + chr(39) + 'transaction_add_detailed_screen.dart' + chr(39) + ';' + chr(10) * 2 + '// ignore_for_file: invalid_use_of_protected_member' + chr(10) * 2 + 'extension TransactionAddDetailedFormUI on _TransactionAddDetailedFormState {' + chr(10) + '  ' + (chr(10)*2 + '  ').join(eu) + chr(10) + '}' + chr(10)
with open('lib/screens/transaction_add_detailed_screen_ui.dart', 'w', encoding='utf-8') as f:
    f.write(c_ui)

c_lg = 'part of ' + chr(39) + 'transaction_add_detailed_screen.dart' + chr(39) + ';' + chr(10) * 2 + '// ignore_for_file: invalid_use_of_protected_member, use_build_context_synchronously' + chr(10) * 2 + 'extension TransactionAddDetailedFormLogic on _TransactionAddDetailedFormState {' + chr(10) + '  ' + (chr(10)*2 + '  ').join(el) + chr(10) + '}' + chr(10)
with open('lib/screens/transaction_add_detailed_screen_logic.dart', 'w', encoding='utf-8') as f:
    f.write(c_lg)

