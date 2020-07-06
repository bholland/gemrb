#!/bin/bash
# GemRB - Infinity Engine Emulator
# Copyright (C) 2009 The GemRB Project
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
#
# this script takes the guiscript docs and prepares them to shine on dokuwiki

docdir="${1:-$PWD/gemrb/docs/en/GUIScript}"
out_dir="${2:-$PWD/guiscript-docs.wikified}"
scriptdir="${3:-$docdir/../../../GUIScripts}"
plugincpp="${4:-$docdir/../../../plugins/GUIScript/GUIScript.cpp}"
index_title="GUIScript function listing"
see_also_str="See also:"

mkdir -p "$out_dir"
rm -f "$out_dir"/*.txt
test -d "$docdir" || exit 1

function dumpDocs() {
  # extract the functions docs from the doc strings into individual files
  sed -n '/PyDoc_STRVAR/,/PyObject/ { /"=/,/"$/ { s,\\n,,; s,\\,,; p} }' "$plugincpp" |
    awk -v RS='"' -v out="$out_dir" \
    '{ split($0, t); title=tolower(t[2]); if (title) print $0 >  out "/" title ".txt" }' || return 1

  # append a link to the function index
  for txt_file in "$out_dir"/*.txt; do
    echo -e '\n[[guiscript:index|Function index]]' >> "$txt_file"
  done

  # dump the special pages
  cp "$docdir"/*.txt "$out_dir"
  rm "$out_dir"/doc_template.txt

  echo "Done, now manually copy the contents of $out_dir to wiki/data/pages/guiscript"
  echo "Tar it up and move to FRS via the web UI or via SCP, eg.:"
  echo "  scp gsd.tgz USERNAME@frs.sourceforge.net:/home/frs/project/gemrb"
}

function convertDocs() {

# intertwine the doc pages based on the "See also" entries
echo Linking ...
for txt_file in "$docdir"/*.txt; do
  cp "$txt_file" "$out_dir/$(basename $txt_file)" || exit 2
  # get the linked pages (all are in one line)
  links=$(grep -m1 "$see_also_str" "$txt_file")
  if [[ -n $links ]]; then
    # we have some links and first we strip off the "See also:"
    links=${links##*:}
    for link in $links; do
      # when there's multiple links, we have to deal with the commas
      if [[ ! -f $docdir/${link//,/}.txt ]]; then
        echo "Dangling link in $(basename $txt_file): ${link//,/}"
        continue
      fi
      if [[ ${link##*,} == "" ]]; then
        # has comma, which we strip and readd, so it doesn't affect the link
        sed_cmd="/$see_also_str/ s@$link@[[guiscript:${link//,/}]],@g"
      else
        sed_cmd="/$see_also_str/ s@$link\>@[[guiscript:$link]]@g"
      fi
      sed -i "$sed_cmd" "$out_dir/$(basename $txt_file)"
    done
  fi
done

echo Formatting ...
cd "$out_dir"
echo > indexX
# add some formatting to the doc pages
for txt_file in *; do
  # extra newlines
  #sed -i "s,$,\n," $txt_file

  # format the title
  if grep -qR --include="*.py" "GemRB\.${txt_file%.*}" "$scriptdir"; then
    # actual script command
    sed -i "1 s,^,===== ${txt_file%.*} =====\n," $txt_file
  if [[ ${txt_file%.*} == controls ]]; then echo juhu0; fi
else
    # miscellaneous doc
    if [[ ${txt_file%.*} != indexX ]]; then
      if [[ ${txt_file//_/} == $txt_file ]]; then
        sed -i "1 s,^,===== ${txt_file%.*} =====\n," $txt_file
      else
        # misc doc with multiword title
        sed -i "1 s,^\([^.]*\)\.*\s*$,===== \1 =====," $txt_file
      fi
    fi
  fi

  # bold the headlines, itemize the parameters and add some links
  sed -i "/\[\[guiscript:/! s@^[^:]\{,20\}:@\n**&**@" $txt_file
  sed -i "/^$see_also_str/ s@^[^:]\{,10\}:@\n**&**@" $txt_file
  echo -e "\n\n[[guiscript:index|Function index]]" >> $txt_file
  sed -i "/Parameters:/,/^[^:]*:\*\*/ { /^[^:]*:\*\*/!s,^\(\s*\S\S*\),  * \1,}" $txt_file
  sed -i '/^\s*$/ {N; /\n\s*$/D }' $txt_file # squeeze repeats of more than 2 newlines
  echo "  * [[guiscript:${txt_file%.*}]]" >> indexX

  [[ ${txt_file%.*} == indexX ]] && continue
  lo_file=$(tr '[[:upper:]]' '[[:lower:]]' <<< $txt_file)
  if [[ $lo_file != $txt_file ]]; then
    mv $txt_file $lo_file
  fi
done
sort -o index.txt indexX
rm indexX
sed -i -e '/guiscript:index/d; /indexX/d' -e "1 s,^,===== $index_title =====\n," index.txt
echo Done.

}

# old logic switch; all paths or no paths
if [[ $1 == convert || $5 == convert ]]; then
  [[ $1 == convert ]] && docdir="$PWD/gemrb/docs/en/GUIScript"
  convertDocs
else
  dumpDocs
fi
