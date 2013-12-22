function setup_variable {
    temp=$1
    eval 'temp=$'$temp
    if [[ $temp ]] && [[ $3 != "h" ]] ; then
        next=$temp
    else
        next=$2
    fi

    if [[ $3 == 'h' ]] ; then
        # hard set, no option
        echo $1'='$next>&3
    else
        echo $1'?='$next>&3
    fi
}

function setup_variables_vala {
    if [[ ! $BINARY ]] ; then
        echo "BINARY variable not defined"
        exit 1 ;
    fi

    setup_variable "BINARY" ""
    setup_variable "CC" "gcc"
    setup_variable "CFLAGS" "$CFLAGS" h
    setup_variable "VALAFLAGS" "$VALAFLAGS" h
    setup_variable "VALAC" "valac"
    setup_variable "LDFLAGS" "$LDFLAGS" h

    # the source directory
    setup_variable "SOURCEDIR" .

    # This is where the byproducts of compilation go
    setup_variable "VALAHEADERDIR" '$(SOURCEDIR)/_include/'
    setup_variable "VALAVAPIDIR" '$(SOURCEDIR)/_vapi/'
    setup_variable "VALACDIR" '$(SOURCEDIR)/_c/'
    setup_variable "OBSDIR" '$(SOURCEDIR)/_obs/'
}

function generate_vala {
    setup_variables_vala
    
    echo -e ''>&3
    echo -e 'all: init | build'>&3
    echo -e ''>&3
    
    echo -e 'init:'>&3
    echo -e '\tmkdir -p $(VALACDIR) $(VALAHEADERDIR) $(VALAVAPIDIR) $(OBSDIR)'>&3
    echo -e ''>&3
    
    cfiles=''
    objects=''
    for i in $SOURCES ; do
        noext=$(echo $i | sed 's/\.vala$//g')
        basename=$(basename $noext) 
    
        header='$(VALAHEADERDIR)/'$basename'.h'
        cfile='$(VALACDIR)/'$basename'.c'
        vapi='$(VALAVAPIDIR)/'$basename'.vapi'
        object='$(OBSDIR)/'$basename'.o'
    
        # depends on vala source
        echo -e "$cfile: $i $cfiles">&3
        echo -e '\t$(VALAC) $(VALAFLAGS) --vapidir $(VALAVAPIDIR) --vapi '$vapi' -H '$header' -C '$i>&3
        echo -e '\t'mv $noext'.c '$cfile>&3
        echo -e ''>&3

        echo -e "$object: $cfile">&3
        echo -e '\t$(CC) $(CFLAGS) -o '$object' -c '$cfile>&3
        echo -e ''>&3

        cfiles="$cfiles $cfile"
        objects="$objects $object"
    done
    echo -e 'build: '$objects''>&3
    echo -e '\t$(CC) $(LDFLAGS) -o $(BINARY) '$objects>&3
    echo -e ''>&3

    echo '
clean:
	rm -rf $(VALACDIR) $(OBSDIR)
'>&3
}

if [ -f genconfig ] ; then
    source genconfig
fi

rm -f Makefile
exec 3<> Makefile
generate_$MAKE_TYPE
# exec 3>&-
