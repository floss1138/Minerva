# Minerva
A messy hack to parse database output provided as xml and tab deliminated list.   
Tab list processing was more advanced than the XML parsing.  If no tabs detected input file is parsed for xml.   
Usage is `minerva_x.pl <filename>`   
For a tabbed list, a directory is created.  Some output is sent to a new <date_stamp>.txt file.   
Several issues exist with the formatting and encoding of the data set.
This is a work in progress hack, tags are hard coded in the script.   

There is a requirement to index on the first character to create a (Winodows) directory structure.
Unintentional spaces and quotes have entered the dataset so these are removed.

WINDOWS-1252 CP1252 8-bit character encoding, shown below as <HEX>, has been replaced with 7 bit ASCII equivalent:   

`<80>` Euro becomes Euro   
`<E9>` e with accent becomes e   
`<C9>` E with accent becomes E    
`<91>` opening single quote becomes '   
`<92>` closing single quote becomes '   
`<93>` open double quote becomes '   
`<94>` close double quote becomes '   
`<95>` bullet point becomes .   
`<96>` CP1252 hyphen small becomes -   
`<97>` CP1252 hyphen large becomes -    

ASCII characters exist that we cannot use in Windows directory names \ / ? ” : |   

Leading spaces and all quote/apostrophe characters '  " are removed (after CP1252 conversion).  Other illegal Windows directory characters are translated to ASCII hyphen.  

/:/-/   
/\\/-/   
/\//-/   
/?/-/   
/|/-/   

For VIM users it is possible to relaod the file with a specified code page, for example cp850, `:e ++enc=cp850`   
Using octal dump with conversion to printable characters can also be useful for troublsome fragents. `od -c <filename>`   
    

