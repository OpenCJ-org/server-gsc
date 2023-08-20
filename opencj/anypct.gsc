#include openCJ\util;

hasAnyPct()
{
    if (isDefined(self.anyPct))
    {
        return self.anyPct;
    }
    return false;
}

setAnyPct(value)
{
    self.anyPct = value;
}

onRunCreated()
{
    // New run started, all any% things are not relevant anymore
    self.anyPct = false;
}

onRunRestored()
{
    // onRunRestored is called after loading, so the loading will have already set this variable properly
}
