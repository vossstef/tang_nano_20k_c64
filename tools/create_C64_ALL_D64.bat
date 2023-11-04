setlocal EnableDelayedExpansion
type NUL > DISKSRAWC64.IMG
FOR %%G IN (*.D64) DO copy /B DISKSRAWC64.IMG+"%%G"+dummyto256.bin DISKSRAWC64.IMG
