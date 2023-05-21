# ACPIpatcher
Very Work-In-Progress...
This code may not work... and for some time it really may not. I make sure to update this readme if the status changes. :) *(pull requests and issues are welcome ~~if there will be any~~)*

## Why ??
My laptop has some trouble with Linux. So I tracked the issue to be tied with my ACPI tables. I found out that using iasl I can't decompile the tables, because they are not written to the ACPI standards and iasl is detecting duplicate methods. (A lot of them actually) This is my script to find "somebiosfile.exe" in your folder, decompile that, grab the tables from there (because I noticed that I am not able to get all of my tables from my system), organize them in a folder and using some **very amateur** bash scripting, get rid of the duplicate methods directly before decompilation, via some hex magic.
## Really ??
It may sound a bit overkill... and it may just be. But I already started this, so even if it won't work in the end I can at least keep the expirience gained. :)

*You are free to use my code and ideas behind it, any way you like, but please respect the license attached.*

Big thank you to all who contributed to https://github.com/LongSoft/UEFITool, I would be lost without these great tools. :)
