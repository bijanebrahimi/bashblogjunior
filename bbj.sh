#!/usr/bin/env bash

# BashBlogJunior, an Improved bashBlog fork written in a single bash script
# Authur: Bijan Ebrahimi <BijanEbrahimi@lavabit.com>
# Original Authur: Carles Fenollosa <carles.fenollosa@bsc.es>

#########################################################################################
#
# README
#
#########################################################################################
#
# This is a very basic blog system
#
# Basically it asks the user to create a sourcefile written in any markup language,
# then converts it into a .html file and then rebuilds the index.html and feed.rss.
#
# Comments are not supported.
#
# This script is standalone, it doesn't require any other file to run
#
# Files that this script generates:
#	- main.css (inherited from Carles Fenollosa page) and blog.css (blog-specific stylesheet)
#	- one .html for each post
#	- index.html (regenerated each run)
# 	- feed.rss (regenerated each run)
#	- all_posts.html (regenerated each run)
# 	- it also generates temporal files, which are mostly removed afterwards
#
# It generates valid html and rss files, so keep care to use valid xhtml when editing a post
#
# posts, drafts and temporary files can be generated in WEB ROOT directory or in a 
# user specific direcroty. files in temporary directory never deletes so it's a good idea
# to use /tmp.

#########################################################################################
#
# LICENSE
#
#########################################################################################
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

#########################################################################################
#
# CHANGELOG
#
#########################################################################################
#
# 0.0.2    BUGFIX: rss datetime
# 0.0.1    added markup language support
#          added sourcefiles feature [containing posts raw content]
#          improved edit functionality
#          sequentially file names for duplicated titles
#          added manual backup menu
#          code refactoring
#          general functional improvements
#          new stylesheet
#          default EDITOR and some other small changes


# Displays the help
usage() {
	echo "$global_software_name v$global_software_version"
	echo "Usage: $0 command [filename]"
	echo ""
	echo "Commands:"
	echo "    init               creates initial files in the current path"
	echo "    post [sourcefile]  insert a new blog post, or the SOURCEFILE of a Template to continue editing it"
	echo "    edit [sourcefile]    edit an already created SOURCEFILE"
	echo "    rebuild [option]   regenerates all/specific pages"
	echo "                       option=[index|archive|posts|rss|css]"
	echo "    reset              deletes blog-generated files. Use with a lot of caution and back up first!"
	echo "    list               list all entries. Useful for debug"
	echo "    backup [output]     backup sourcefiles"
	echo ""
	echo "For more information please open $0 in a code editor and read the header and comments"
}

# Global variables
# It is recommended to perform a 'rebuild' after changing any of this in the code
global_variables() {
    #~ Markup Language
    global_markup="markdown"
    global_markdown_application="/usr/bin/markdown"
    global_markdown_cmd="$global_markdown_application --html4tags"
    global_markdown_extension="md"
    
    #~ Directories
    global_post_directory=""
    global_temp_directory="/tmp/"
    global_temp_prefix=".bbj-"
    global_template_directory="drafts/"
    
    #~ Autobackup
    global_autobackup="no"
    
    # Applications info
    global_software_name="BashBlogJunior"
    global_software_version="0.0.2"

    # Blog title
    global_title="Blog Title"
    # The typical subtitle for each blog
    global_description="Blog Description"
    # The public base URL for this blog
    global_url="http://example.com/"

    # Your name
    global_author="Blog Author"
    # You can use twitter or facebook or anything for global_author_url
    global_author_url="http://example.com/authur" 
    # Your email
    global_email="author@example.com"

    # CC by-nc-nd is a good starting point, you can change this to "&copy;" for Copyright
    global_license="CC by-nc-nd"

    # If you have a Google Analytics ID (UA-XXXXX), put it here.
    # If left empty (i.e. "") Analytics will be disabled
    global_analytics=""

    # Leave this empty (i.e. "") if you don't want to use feedburner, 
    # or change it to your own URL
    global_feedburner=""

    # Leave these empty if you don't want to use twitter for comments
    global_social="yes"
    global_social_name="identica"
    global_social_username="bijan"
    global_social_url="https://identi.ca/bijan"
    global_social_text="Leave your Comments on Identi.ca"

    # Blog generated files
    # index page of blog (it is usually good to use "index.html" here)
    index_file="index.html"
    number_of_index_articles="8"
    # global archive
    archive_index="archive.html"
    # feed file (rss in this case)
    blog_feed="feed.rss"
    number_of_feed_articles="20"

    # Localization and i18n
    # "Comments?" (used in twitter link after every post)
    # "View more posts" (used on bottom of index page as link to archive)
    template_archive="View more posts"
    # "Back to the index page" (used on archive page, it is link to blog index)
    template_archive_index_page="Back to the index page"
    # "Subscribe" (used on bottom of index page, it is link to RSS feed)
    template_subscribe="Subscribe"
    # "Subscribe to this page..." (used as text for browser feed button that is embedded to html)
    template_subscribe_browser_button="Subscribe to this page..."
    # The locale to use for the dates displayed on screen (not for the timestamps)
    date_format="%B %d, %Y"
    date_locale="C"
}

# generates templates
create_html_header() {
	if [ "$global_feedburner" == "" ]; then
        feed_url=$blog_feed
    else 
		feed_url=$global_feedburner
    fi
    google_analytics_code=$(google_analytics)
	cat << EOF
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" 
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
	<head>
		<meta http-equiv="Content-type" content="text/html;charset=UTF-8" />
		<link rel="stylesheet" href="main.css" type="text/css" />
		<link rel="stylesheet" href="blog.css" type="text/css" />
		<link rel="alternate" type="application/rss+xml" title="'$template_subscribe_browser_button'" href="'$feed_url'" />
		$google_analytics_code
EOF
}
create_html_footer() {
	protected_mail="$(echo "$global_email" | sed 's/@/\&#64;/g' | sed 's/\./\&#46;/g')"
	cat << EOF
<div id="footer">$global_license <a href="$global_author_url">$global_author</a> &mdash; <a href="mailto:$protected_mail">$protected_mail</a></div>
EOF
}
create_html_title() {
	cat << EOF
	<h1 class="nomargin">
		<a class="ablack" href="$global_url">$global_title</a>
	</h1>
	<div id="description">$global_description</div>
EOF
}

# Prints the required google analytics code
google_analytics() {
    if [ "$global_analytics" == "" ]; then return; fi

    echo "<script type=\"text/javascript\">

    var _gaq = _gaq || [];
    _gaq.push(['_setAccount', '"$global_analytics"']);
    _gaq.push(['_trackPageview']);

    (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
})();

</script>"
}

# Delete all generated content, leaving only this script
reset() {
    echo "Are you sure you want to delete all blog entries? Please write \"Yes, I am!\" "
    read line
    if [ "$line" == "Yes, I am!" ]; then
        rm *.html *.$global_markdown_extension *.rss *.css 2>/dev/null
        echo "Deleted all posts, stylesheets and feeds."
    else
        echo "Phew! You dodged a bullet there. Nothing was modified."
    fi
}

initial() {
	echo -n "Initializing  ... "
	rebuild_all "no" "no" "no" "no" "yes"
	echo "finished"
}

backup() {
	if [ "$1" == "" ]; then
		backup_output=".backup-$(date +'%Y-%m-%d')"
	else
		backup_output="$1"
	fi
	echo -n "moving source files to $backup_output.tar.gz ... "
	tar cfz "$backup_output.tar.gz" *.$global_markdown_extension
	echo "finished"
}

# Displays a list of the posts
list_posts() {
	sourcelist=$(ls -t $global_post_directory*.$global_markdown_extension)
	list="No#TITLE#SOURCE\n"
	counter=1
	for sourcefile in $sourcelist; do
		single_post_title=$(cat $sourcefile | head -n 1)
		list="$list$counter#$single_post_title#$sourcefile\n"
		counter=$(( $counter + 1 ))
	done
	echo -e "$list" | column -t -s "#"
			
}

# Initial dependency Checkings
initial_check() {
	# Check for Markup language
	if [[ ! -f "$global_markdown_application" ]] || [[ ! -x "$global_markdown_application" ]]; then
		echo "$global_markdown_application is not installed"
		exit
	fi
	
	# Check for Directories
	if [[ ! -z "$global_post_directory" ]] && [[ ! -d "$global_post_directory" ]]; then
		echo "Posts directory is missing"
		echo "   mkdir $global_post_directory"
		exit
	fi
	if [[ ! -z "$global_temp_directory" ]] && [[ ! -d "$global_temp_directory" ]]; then
		echo "Temp directory is missing"
		echo "   mkdir $global_temp_directory"
		exit
	fi
	if [[ ! -z "$global_template_directory" ]] && [[ ! -d "$global_template_directory" ]]; then
		echo "Drafts directory is missing"
		echo "   mkdir $global_template_directory"
		exit
	fi
}

# Manages the creation/editing of the sourcefile and the parsing to html file
# also the drafts
# 
# $1      [existing] source file
# $2      edit mode
write_entry() {
    if [ "$1" != "" ]; then
        TMPFILE="$1"
        if [ ! -f "$TMPFILE" ]; then
            echo "The template doesn't exist"
            exit
        elif [ "$2" == "yes" ]; then
			#~ Only make parse_file not to find a unique filename_html_unique
			disable_finding_unique_name="yes"
			current_sourcefile_timestamp=$(date -r "$1")
        fi
    else
        TMPFILE="${global_temp_directory}${global_temp_prefix}entry-$RANDOM"
        echo "one-line Post Title" >> "$TMPFILE"
        echo "" >> "$TMPFILE"
        echo "Your ${global_markup} content Here" >> "$TMPFILE"
    fi

    post_status="B"
    while [ "$post_status" != "p" ] && [ "$post_status" != "P" ]; do
		$EDITOR "$TMPFILE"
		if [ "$disable_finding_unique_name" == "yes" ]; then
			touch -d "$current_sourcefile_timestamp" "$TMPFILE"
		fi
        parse_file "$TMPFILE" # this command sets $filename as the html processed file
        chmod 600 "$filename_html_unique"

        echo -n "Preview? (Y/n) "
        read p
        if [ "$p" != "n" ] && [ "$p" != "N" ]; then
            chmod 644 "$filename_html_unique"
            echo "Open $global_url$global_post_directory$filename_html_unique in your browser"
        fi
        #~ FIX: change Draft to Template
        echo -n "[P]ost this entry, [B]ack to editor, [T]emplate, [E]xit? (p/B/t/e) "
        read post_status
        if [ "$post_status" == "e" ] || [ "$post_status" == "E" ]; then
			exit
        fi
        if [ "$post_status" == "t" ] || [ "$post_status" == "T" ]; then
			rm "$filename_html_unique"
			TIME=$(date +"%Y-%m-%d-%H-%M-%S")
			templatename="$global_template_directory$TIME-$filename_markup_unique"
			mv "$filename_markup_unique" "$templatename"
			chmod 600 "$templatename"
			echo -e "\tto continue Editing: "
			echo -e "\t$0 post $templatename"
			exit
        fi
        if [ "$post_status" == "p" ] || [ "$post_status" == "P" ]; then
			chmod 644 "$filename_html_unique"
			echo -n "Post Created. Automatically Rebuild the indexes? (Y/n) "
			rebuild_status="y"
			read rebuild_status
			if [ "$rebuild_status" != "n" ] && [ "$rebuild_status" != "N" ]; then
				echo "Rebuilding Index & Archive & Posts & RSS "
				rebuild_all "yes" "yes" "yes" "yes" "no"
			fi
			exit
        fi
        if [ "$disable_finding_unique_name" != "yes" ]; then
			rm "$filename_html_unique"
			NEW_TMPFILE="$global_temp_directory$global_temp_prefix$RANDOM.$global_markdown_extension"
			mv "$filename_markup_unique" "$NEW_TMPFILE"
			chmod 600 "$NEW_TMPFILE"
			TMPFILE=$NEW_TMPFILE
		fi
    done
}

# Parse the plain text file into an html file
parse_file() {
    # Read for the title and check that the filename is ok
    title=""
    content=""
    filename_markup_unique="$TMPFILE"
	filename_html_unique=$(echo "$TMPFILE" | sed 's/.'$global_markdown_extension'/.html/g')
	#~ echo "$disable_finding_unique_name $TMPFILE $filename_markup_unique $filename_html_unique"
	#~ exit
    while read line; do
        if [ "$title" == "" ]; then
            title="$line"
            if [ "$disable_finding_unique_name" != "yes" ]; then
				filename="$(echo $title | tr [:upper:] [:lower:])"
				filename="$(echo $filename | sed 's/\ /-/g')"
				filename="$(echo $filename | tr -dc '[:alnum:]-')" # html likes alphanumeric
				
				filename_markup="$global_post_directory$filename.$global_markdown_extension"
				filename_html="$global_post_directory$filename.html"
				
				# Check for duplicate file names
				suffix=1
				filename_markup_unique=$filename_markup
				filename_html_unique=$filename_html
				while [ -f "$filename_html_unique" ]; do
					echo 
					suffix=$(echo "$suffix + 1" | bc)
					filename_markup_unique="$(echo $filename_markup | sed 's/.'$global_markdown_extension'/'-$suffix'.'$global_markdown_extension'/g')"
					filename_html_unique="$(echo $filename_html | sed 's/.html/'-$suffix'.html/g')"
				done
            fi
        fi
        if [ "$disable_finding_unique_name" != "yes" ]; then
			echo "$line" >> "$filename_markup_unique"
		fi
    done < "$TMPFILE"

    # Create the actual html page
    create_html_page "$filename_markup_unique" "$filename_html_unique" no "$title"
}

# Create html files from source files
# $1     the source file
# $2     the output file
# $3     "yes" if we want to generate the index.html,
#        "no" to insert new blog posts
# $4     title for the html header
# $5     optional original blog date [YYYY/MM/DD[ HH:MM]]
create_html_page() {
	content=$(tail -n +1 "$1" | $global_markdown_cmd)
    output="$2"
    url="$output"
    index="$3"
    title="$4"
    timestamp="$5"
    if [ "$timestamp" == "" ]; then
		timestamp=$(date -r "$1" +"%Y/%m/%d %H:%M")
    fi
    
    generate_html_page "$content" "$url" "$index" "$title" "$timestamp" > "$output"
    touch -d "$timestamp" "$output"
}

# Generates page html content
# $1     html content
# $2     file url
# $3     "yes" if we want to generate the index.html,
#        "no" to insert new blog posts
# $4     title for the html header
# $5     blog date
generate_html_page() {
    content=$1
    file_url="$2"
    index="$3"
    title="$4"
    blog_date="$5"
    
    single_post_header=""
    single_post_footer=""
    
    if [ "$index" == "no" ]; then
		date=$(LC_ALL=date_locale date -d "$blog_date" +"$date_format")
		single_post_header="<h3><a class='ablack' href='$global_url$file_url'>$title</a></h3><div class='subtitle'>$date &mdash; $global_author</div>"
		#~ FIX: comment section
		single_post_footer="<div id='post_footer $global_social_name'><div id='post_footer'><a href='$global_url'>$template_archive_index_page</a>"
		if [ "$global_social" = "yes" ]; then
			single_post_footer="$single_post_footer &mdash; <a href='$global_social_url'>$global_social_text</a></div>"
		fi
		single_post_footer="$single_post_footer </div>"
    fi
    
    html_header=$(create_html_header)
    html_footer=$(create_html_footer)
    html_title=$(create_html_title)
    #~ FIX: google_analytics
    #~ html_google_analytics=google_analytics
    
    cat << EOF
$html_header
<title>$title</title>
$html_google_analytics
</head>
<body>
	<div id="divbodyholder">
		<div class="headerholder">
			<div class="header">
				<div id="title">
					$html_title
				</div>
			</div>
		</div>
		<div id="divbody">
			<div class="content">
				<!-- entry begin -->
				$single_post_header
				<!-- text begin -->
				$content
				<!-- text end -->
				$single_post_footer
				<!-- entry end -->
			</div>
			$html_footer
		</div>
	</div>
</body>
</html>
EOF
}

# Rebuild all resources
# $1      index [yes/no]
# $2      archive [yes/no]
# $3      entries [yes/no]
# $4      rss [yes/no]
# $5      css [yes/no]
rebuild_all() {
	rebuild_index=$1
	rebuild_archive=$2
	rebuild_entries=$3
	rebuild_rss=$4
	rebuild_css=$5
	current_timestamp="$(date +'%Y/%m/%d %k:%M')"
	current_rss_timestamp="$(date -R)"
	
	if [ "$1" == "yes" ] || [ "$2" == "yes" ] || [ "$3" == "yes" ] || [ "$4" == "yes" ]; then
		counter=0
		index_content=""
		archive_content=""
		rss_content=""
		sourcelist=$(ls -t $global_post_directory*.$global_markdown_extension)
		for sourcefile in $sourcelist; do
			echo -e "\t$sourcefile"
			
			single_post_url=$(echo $sourcefile | sed "s/$global_markdown_extension\$/html/")
			single_post_title=$(cat $sourcefile | head -n 1)
			single_post_timestamp="$(date -r $sourcefile +'%Y/%m/%d %k:%M')"
			single_post_date=$(LC_ALL=date_locale date -d "$single_post_timestamp" +"$date_format")
			single_post_title=$(cat $sourcefile | head -n 1)
			
			#~ Rebuild Index
			if [ "$1" == "yes" ]; then
				if [ "$counter" -ge "$number_of_index_articles" ]; then break; fi
				index_single_post_header="<h3><a class='ablack' href='$global_url$single_post_url'>$single_post_title</a></h3><div class='subtitle'>$single_post_date &mdash; $global_author</div>"
				index_single_post_content=$(tail -n +2 "$sourcefile" | $global_markdown_cmd)
				index_content="$index_content $index_single_post_header $index_single_post_content"
			fi
			
			#~ Rebuild archive
			if [ "$2" == "yes" ]; then
				archive_content="$archive_content <li><a href='$global_url$single_post_url'>$single_post_title</a> &mdash; $single_post_date</li>"
			fi
			
			#~ Rebuild entries
			if [ "$3" == "yes" ]; then
				#~ create_html_page "$sourcefile" "$single_post_url" no "$single_post_title"
				index_single_post_content=$(tail -n +2 "$sourcefile" | $global_markdown_cmd)
				generate_html_page "$index_single_post_content" "$single_post_url" "no" "$single_post_title" "$single_post_date" > "$single_post_url"
				chmod 644 "$single_post_url"
			fi
			
			#~ Rebuild RSS
			if [ "$4" == "yes" ]; then
				if [ "$counter" -ge "$number_of_feed_articles" ]; then break; fi
				index_single_post_content=$(tail -n +2 "$sourcefile" | $global_markdown_cmd)
				rss_single_post_date=$(date -r "$sourcefile" -R)
				rss_single_content="<item><title>$single_post_title</title>"
				rss_single_content="$rss_single_content <description><![CDATA[$index_single_post_content]]></description>"
				rss_single_content="$rss_single_content <link>$global_url/$single_post_url</link>"
				rss_single_content="$rss_single_content <guid>$global_url/$single_post_url</guid>"
				rss_single_content="$rss_single_content <dc:creator>$global_author</dc:creator>"
				rss_single_content="$rss_single_content <pubDate>$rss_single_post_date</pubDate></item>"
				rss_content="$rss_content $rss_single_content"
			fi
			
			counter=$(( $counter + 1 ))
		done
    fi
    
    #~ Save Index
    if [ "$1" == "yes" ]; then
		if [ "$global_feedburner" == "" ]; then
			index_content="$index_content <div id='post_footer'><a href='$archive_index'>View more posts</a> &mdash; <a href='$blog_feed'>$template_subscribe</a></div>"
		else
			index_content="$index_content <div id='post_footer'><a href='$archive_index'>$template_archive</a> &mdash; <a href='$global_feedburner'>Subscribe</a></div>"
		fi
		generate_html_page "$index_content" "$single_post_url" "yes" "$global_title" "$current_timestamp" > "$index_file"
		chmod 644 "$index_file"
    fi
    
    #~ Save archive
    if [ "$2" == "yes" ]; then
		archive_content="<h3>All posts</h3><ul>$archive_content</ul><div id='post_footer'><a href='$global_url'>$template_archive_index_page</a></div>"
		generate_html_page "$archive_content" "$archive_index" "yes" "$global_title &mdash; All posts" > "$archive_index"
		chmod 644 "$archive_index"
    fi
    
    #~ Save RSS
    if [ "$4" == "yes" ]; then
		cat > "$blog_feed" <<EOF
<?xml version='1.0' encoding='UTF-8' ?>
<rss version='2.0' xmlns:atom='http://www.w3.org/2005/Atom' xmlns:dc='http://purl.org/dc/elements/1.1/'>
	<channel>
		<title>$global_title</title>
		<link>$global_url</link>
		<description>$global_description</description><language>en</language>
		<lastBuildDate>$current_rss_timestamp</lastBuildDate>
		<pubDate>$current_rss_timestamp</pubDate>
		<atom:link href='$global_url/$blog_feed' rel='self' type='application/rss+xml' />
		$rss_content
	</channel>
</rss>
EOF
		chmod 644 "$blog_feed"
    fi
    
    #~ Rebuild CSS
    if [ "$5" == "yes" ]; then
		create_css
    fi
}

# Create the css file from scratch
create_css() {
    # To avoid overwriting manual changes. However it is recommended that
    # this function is modified if the user changes the blog.css file.
    # blog.css directives will be loaded after main.css and thus will prevail
        cat > "blog.css" << EOF
#title{font-size: x-large;}
a.ablack{color:black !important;}
li{margin-bottom:8px;}
ul,ol{margin-left:24px;margin-right:24px;}
#post_footer{margin-top:24px;text-align:center;}
.subtitle{font-size:small;margin:12px 0px;color:#999;position:relative;top:-10px;}
.content p{margin-left:24px;margin-right:24px;}
h1{margin-bottom:12px !important;}
#description{font-size:large;margin-bottom:12px;}
h3{margin-top:42px;margin-bottom:8px;}
h4{margin-left:24px;margin-right:24px;}
#twitter{line-height:20px;vertical-align:top;text-align:right;font-style:italic;color:#333;margin-top:24px;font-size:14px;}

.content{color:#373737; font: 16px Helvetica, arial, freesans, clean, sans-serif;}
.content p{line-height:22px;}
.content h1{font-size:28px;font-weight: bold;}
.content a{color:#0086B3;}
.content a:hover{text-decoration:underline !important}
.content code{overflow: auto;padding:2px 5px;background-color:#f8f8f8; border:1px solid #ccc;font-family: Consolas, "Liberation Mono", Courier, monospace;}
.content pre code{display:block;}
.content ul{list-style-type: disc;}
.content img{width: 400px;padding: 1px;border: 1px solid #4D4D4D;}
EOF

		cat > "main.css" << EOF
body{font-family:Georgia,"Times New Roman",Times,serif;margin:0;padding:0;background-color:#F3F3F3;}
#divbodyholder{padding:5px;background-color:#DDD;width:874px;margin:24px auto;}
#divbody{width:776px;border:solid 1px #ccc;background-color:#fff;padding:0px 48px 24px 48px;top:0;}
.headerholder{background-color:#f9f9f9;border-top:solid 1px #ccc;border-left:solid 1px #ccc;border-right:solid 1px #ccc;}
.header{width:800px;margin:0px auto;padding-top:24px;padding-bottom:8px;}
.content{margin-bottom:45px;}
.nomargin{margin:0;}
.description{margin-top:10px;border-top:solid 1px #666;padding:10px 0;}
h3{font-size:20pt;width:100%;font-weight:bold;margin-top:32px;margin-bottom:0;}
.clear{clear:both;}
#footer{padding-top:10px;border-top:solid 1px #666;color:#333333;text-align:center;font-size:small;font-family:"Courier New","Courier",monospace;}
a{text-decoration:none;color:#003366;}
a:visited{text-decoration:none;color:#336699;}
blockquote{font-style:italic;background-color:#f9f9f9;border:1px solid #e9e9e9;border-left:solid 12px #e9e9e9;margin:0 20px;padding:12px 12px 12px 24px;}
blockquote img{margin:12px 0px;}
blockquote iframe{margin:12px 0px;}
EOF
}

# Main function
# Encapsulated on its own function for readability purposes
#
# $1     command to run
# $2     file name of a draft to continue editing (optional)
do_main() {
    global_variables

    # Check for $EDITOR
    if [[ -z "$EDITOR" ]]; then
        if [[ ! -x /bin/nano ]]; then
			echo "Please set your \$EDITOR environment variable"
			exit
		fi
		EDITOR="nano"
    fi
	
    # Check for validity of argument
    if [ "$1" != "init" ] && [ "$1" != "reset" ] && [ "$1" != "backup" ] && [ "$1" != "post" ] && [ "$1" != "rebuild" ] && [ "$1" != "list" ] && [ "$1" != "edit" ]; then 
        usage; exit; 
    fi
    
    # Initial Check
    initial_check

    if [ "$1" == "post" ]; then
		write_entry "$2"
		if [ "$global_autobackup" == "yes" ]; then
			backup
		fi
	fi
	if [ "$1" == "edit" ]; then
		write_entry "$2" "yes" 
		if [ "$global_autobackup" == "yes" ]; then
			backup
		fi
	fi
    if [ "$1" == "rebuild" ]; then
		if [ "$2" == "index" ]; then
			echo "Rebuilding Index "
			rebuild_all "yes" "no" "no" "no" "no"
		elif [ "$2" == "archive" ]; then
			echo "Rebuilding Archive "
			rebuild_all "no" "yes" "no" "no" "no"
		elif [ "$2" == "posts" ]; then
			echo "Rebuilding Posts "
			rebuild_all "no" "no" "yes" "no" "no"
		elif [ "$2" == "rss" ]; then
			echo "Rebuilding RSS "
			rebuild_all "no" "no" "no" "yes" "no"
		elif [ "$2" == "css" ]; then
			echo "Rebuilding CSS "
			rebuild_all "no" "no" "no" "no" "yes"
		else
			echo "Rebuilding ALL "
			rebuild_all "yes" "yes" "yes" "yes" "yes"
		fi
	fi
    if [ "$1" == "reset" ]; then reset; fi
    if [ "$1" == "list" ]; then list_posts; fi
    if [ "$1" == "backup" ]; then backup "$2"; fi
    if [ "$1" == "init" ]; then initial; fi
}

#
# MAIN
# Do not change anything here. If you want to modify the code, edit do_main()
#
do_main $*
