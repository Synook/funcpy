lit = lambda n: lambda: n # literal function
sym_4200 = fpy_multiply = lambda a: lambda b: lambda: a () * b ()
sym_4500 = fpy_minus = lambda a: lambda b: lambda: a () - b ()
sym_4300 = fpy_plus = lambda a: lambda b: lambda: a () + b ()
sym_4700 = fpy_div = lambda a: lambda b: lambda: a () / b ()
sym_6200 = fpy_gt = lambda a: lambda b: lambda: a () > b ()
sym_6161 = fpy_eq = lambda a: lambda b: lambda: a () == b ()
sym_6300 = fpy_choice = lambda cond: lambda t: lambda f: lambda: (
    t () if cond () else f ()
) # ?
fpy_emptylist = lambda: [] # i.e., [] in haskell
sym_5800 = fpy_cons = lambda x: lambda xs: lambda: (x, xs) # :
fpy_head = lambda xs: lambda: xs()[0]()
fpy_tail = lambda xs: lambda: xs()[1]()
sym_4242 = fpy_concat = lambda xs: lambda ys: lambda: (
    None
)
fpy_false = lambda: False
fpy_true = lambda: True

def fpy_dirty_print (a):
    print(printr(a))
    return a
def printr (a, inside = False):
    if type(a ()) is tuple:
        lstr = "%s:%s" % (printr(a()[0],True),printr(a()[1]))
        return "(%s)" % lstr if inside else lstr
    else: return a ()
