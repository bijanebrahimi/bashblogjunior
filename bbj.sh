#!/usr/bin/env bash

# BashBlogJunior, an Improved bashBlog fork written in a single bash script
# Authur: Bijan Ebrahimi <BijanEbrahimi@lavabit.com>
# Original Authur: Carles Fenollosa <carles.fenollosa@bsc.es>

# Displays the help
usage() {
	echo "$global_software_name v$global_software_version"
	echo "Usage: $0 command [filename]"
	echo ""
	echo "Commands:"
	echo "    init               creates initial files in the current path"
	echo "    post [sourcefile]  insert a new blog post, or the SOURCEFILE of a Template to continue editing it"
	echo "    edit [sourcefile]  edit an already created SOURCEFILE"
	echo "    rm   [sourcefile]  remove blog entry"
	echo "    rebuild [option]   regenerates all/specific pages"
	echo "                       option=[index|archive|posts|rss|css]"
	echo "    reset              deletes blog-generated files. Use with a lot of caution and back up first!"
	echo "    list               list all entries. Useful for debug"
	echo "    backup [output]    backup sourcefiles"
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
    
    #~ Editor
    global_editor="/bin/nano"
    
    #~ Directories
    global_post_directory=""
    global_tmp_directory="/tmp/"
    global_tmp_prefix=".bbj-"
    
    #~ Template
    global_tmplate_directory="templates/"
    
    #~ Autobackup
    global_autobackup="no"
    global_backup_date_format="%Y-%m-%d"
    
    # Applications info
    global_software_name="BashBlogJunior"
    global_software_version="0.1.0"
    global_software_url="https://github.com/bijanebrahimi/bashblogjunior"

    # Blog information
    global_title="Blog Title"
    global_description="Blog Description"
    global_url="http://example.com/"

    # Author information
    global_author="Blog Author"
    global_author_url="http://example.com/authur" 
    global_email="author@example.com"

    # CC by-nc-nd is a good starting point, you can change this to "&copy;" for Copyright
    global_license="CC by-nc-nd"

    # If you have a Google Analytics ID (UA-XXXXX), put it here.
    # If left empty (i.e. "") Analytics will be disabled
    global_analytics=""
	
	# DISQUS
	global_disqus_shortname=''
	
    # Leave this empty (i.e. "") if you don't want to use feedburner, 
    # or change it to your own URL
    global_feedburner=""

    # Blog generated files
    index_file="index.html"
    number_of_index_articles="8"
    archive_index="archive.html"
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
    template_read_more="Continue Reading ..."
    # The locale to use for the dates displayed on screen (not for the timestamps)
    global_date_format="%B %d, %Y"
    global_date_locale="C"
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
		<link rel="alternate" type="application/rss+xml" title="$template_subscribe_browser_button" href="$feed_url" />
		$google_analytics_code
EOF
}
create_html_footer() {
	protected_mail="$(echo "$global_email" | sed 's/@/\&#64;/g' | sed 's/\./\&#46;/g')"
	cat << EOF
<div id="footer">
	$global_license <a href="$global_author_url">$global_author</a> &mdash; <a href="mailto:$protected_mail">$protected_mail</a><br>
	<i><a href='$global_url'>$global_title</a><i> is powered by <i><a href='$global_software_url'>$global_software_name $global_software_version</a></i>
</div>

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

# retrieve Post Contents
get_srcfile_title() {
	head -n 1 "$1" 2>/dev/null
}
get_srcfile_short_text() {
	line_breaker_regex="<!\-\- (.*) \-\->"
	get_srcfile_full_text "$1" | while read line; do
		if [[ $line =~ $line_breaker_regex ]]; then
			break
		fi
		echo "$line"
	done
}
get_srcfile_full_text() {
	tail -n +2 "$1" 2>/dev/null
}

# Prints the required google analytics code
google_analytics() {
    if [ "$global_analytics" == "" ]; then return; fi

    echo "<script type=\"text/javascript\">

    var _gaq = _gaq || [];
    _gaq.push(['_setAccount', '$global_analytics']);
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
        echo "Deleted all the posts, stylesheets and feed."
    else
        echo "Phew! You dodged a bullet there. Nothing was modified."
    fi
}

# Create CSS files
initial() {
	echo -n "Initializing  ... "
	rebuild_all "no" "no" "no" "no" "yes"
	echo "finished"
}

# Backup Sourcefiles
#
# $1      backup file name, if nothing passed global_backup_date_format will be used
backup() {
	if [ "$1" == "" ]; then
		backup_output=".backup-$(date +"$global_backup_date_format")"
	else
		backup_output="$1"
	fi
	echo "copying source files to $backup_output.tar.gz"
	tar cvfz "$backup_output.tar.gz" *.$global_markdown_extension
	echo "finished"
}

# Displays a list of the posts
list_posts() {
	srcfile_lists=$(ls -t $global_post_directory*.$global_markdown_extension)
	list="No#TITLE#SOURCE\n"
	counter=1
	for sourcefile in $srcfile_lists; do
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
	if [[ ! -z "$global_tmp_directory" ]] && [[ ! -d "$global_tmp_directory" ]]; then
		echo "Temp directory is missing"
		echo "   mkdir $global_tmp_directory"
		exit
	fi
	if [[ ! -z "$global_tmplate_directory" ]] && [[ ! -d "$global_tmplate_directory" ]]; then
		echo "Drafts directory is missing"
		echo "   mkdir $global_tmplate_directory"
		exit
	fi
}

# date functions
template_prefix() {
	date +"%Y-%m-%d-%H-%M-%d"
}
modification_date() {
	if [ -f "$1" ]; then
		date -R -r "$1"
	else
		date -R
	fi
}
formatted_date() {
	LC_ALL="$global_date_locale"
	date -d "$1" +"$2"
}

# Removes existing blog entry
# 
# $1      existing source file
remove_entry() {
	if [ ! -f "$1" ]; then
		echo "source file doesn't exist"
		exit
	fi
	srcfile="$1"
	htmlfile=$(echo "$srcfile" | sed 's/.'$global_markdown_extension'/.html/g')
	
	echo -n "Do you want to remove this entry? (y/N) "
	read remove_status
	if [ "$remove_status" == "y" ] || [ "$remove_status" == "Y" ]; then
		rm "$srcfile" "$htmlfile" 2>/dev/null
		echo "removing $srcfile ..."
		echo "removing $htmlfile ..."
		rebuild_interactive "do you want to rebuild the pages? (y/N)" "yes" "yes" "no" "yes" "no"
	else
		echo "nothing removed"
	fi
}

# Disqus
disqus() {
	cat <<EOF
<div id="disqus_thread"></div>
<script type="text/javascript">
	/* * * CONFIGURATION VARIABLES: EDIT BEFORE PASTING INTO YOUR WEBPAGE * * */
	var disqus_shortname = '$global_disqus_shortname'; // required: replace example with your forum shortname

	/* * * DON'T EDIT BELOW THIS LINE * * */
	(function() {
		var dsq = document.createElement('script'); dsq.type = 'text/javascript'; dsq.async = true;
		dsq.src = '//' + disqus_shortname + '.disqus.com/embed.js';
		(document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(dsq);
	})();
</script>
<noscript>Please enable JavaScript to view the <a href="http://disqus.com/?ref_noscript">comments powered by Disqus.</a></noscript>
<a href="http://disqus.com" class="dsq-brlink">comments powered by <span class="logo-disqus">Disqus</span></a>
EOF
}

# Manages the creation/editing of the sourcefile and the parsing to html file
# also the drafts
# 
# $1      [existing] source file
# $2      edit mode
write_entry() {
	if [ "$1" != "" ]; then
        SRCFILE="$1"
        if [ ! -f "$SRCFILE" ]; then
            echo "The template doesn't exist"
            exit
        elif [ "$2" == "yes" ]; then
			edit_mode="yes"
			current_srcfile_modification_date=$(modification_date "$SRCFILE")
			#~ disable_finding_unique_name="yes"
        fi
    else
        SRCFILE="${global_tmp_directory}${global_tmp_prefix}entry-$RANDOM"
        echo "One Line Post Title" >> "$SRCFILE"
        echo "" >> "$SRCFILE"
        echo "Your ${global_markup} Content Here" >> "$SRCFILE"
        echo "" >> "$SRCFILE"
        echo "<!-- Content Breaker -->" >> "$SRCFILE"
        echo "" >> "$SRCFILE"
        echo "Continue ..." >> "$SRCFILE"
    fi

    post_status="B"
    while [ "$post_status" != "p" ] && [ "$post_status" != "P" ]; do
		$EDITOR "$SRCFILE" 2>/dev/null
		if [ "$edit_mode" == "yes" ]; then
			touch -d "$current_srcfile_modification_date" "$SRCFILE"
		fi
        parse_file "$SRCFILE"
        chmod 600 "$htmlfile_unique_name"

        echo -n "Preview? (Y/n) "
        read preview
        if [ "$preview" != "n" ] && [ "$preview" != "N" ]; then
            chmod 644 "$htmlfile_unique_name"
            echo "Open $global_url$global_post_directory$htmlfile_unique_name in your browser"
        fi
        
        echo -n "[P]ost this entry, [B]ack to editor, [T]emplate it, [E]xit? (p/B/t/e) "
        read post_status
        if [ "$post_status" == "e" ] || [ "$post_status" == "E" ]; then
			echo "Rebuild the indexes manually if you want the last changes take effect"
			exit
        fi
        if [ "$post_status" == "t" ] || [ "$post_status" == "T" ]; then
			srcfile_template_prefix=$(template_prefix)
			srcfile_template="$global_tmplate_directory$srcfile_template_prefix-$srcfile_unique_name"
			cp "$srcfile_unique_name" "$srcfile_template"
			chmod 600 "$srcfile_template"
			echo -e "Template created [$srcfile_template]"
			echo -n "Do you want to remove the source file? (Y/n) "
			read template_status
			if [ "$template_status" != "n" ] && [ "$template_status" != "N" ]; then
				rm "$htmlfile_unique_name" "$srcfile_unique_name" 2>/dev/null
				rebuild_interactive "Rebuild the indexes? (Y/n) " "yes" "yes" "no" "yes" "no"
			fi
			exit
        fi
        if [ "$post_status" == "p" ] || [ "$post_status" == "P" ]; then
			chmod 644 "$htmlfile_unique_name"
			rebuild_interactive "Post Created. Automatically Rebuild the indexes? (Y/n) "  "yes" "yes" "yes" "yes" "no"
			exit
        fi
        if [ "$edit_mode" != "yes" ]; then
			rm "$htmlfile_unique_name"
			NEW_SRCFILE="$global_tmp_directory$global_tmp_prefix$RANDOM.$global_markdown_extension"
			mv "$srcfile_unique_name" "$NEW_SRCFILE"
			chmod 600 "$NEW_SRCFILE"
			SRCFILE=$NEW_SRCFILE
		fi
    done
}

# Parse the plain text file into an html file
parse_file() {
    # Read for the title and check that the filename is ok
    content=""
    title=$(get_srcfile_title "$SRCFILE")
    #~ title=$(head -n 1 "$SRCFILE")
    if [ "$edit_mode" != "yes" ]; then
		filename="$(echo $title | tr [:upper:] [:lower:])"
		filename="$(echo $filename | sed 's/\ /-/g')"
		filename="$(echo $filename | tr -dc '[:alnum:]-')" # html likes alphanumeric
		srcfile_unique_name="$global_post_directory$filename.$global_markdown_extension"
		srcfile_name=$srcfile_unique_name
		suffix=1
		#~ BUG: what if the title was index?
		while [ -f "$srcfile_unique_name" ]; do
			suffix=$(( $suffix + 1 ))
			srcfile_unique_name="$(echo $srcfile_name | sed 's/.'$global_markdown_extension'/'-$suffix'.'$global_markdown_extension'/g')"
		done
	else
		srcfile_unique_name="$SRCFILE"
	fi
	htmlfile_unique_name=$(echo "$srcfile_unique_name" | sed 's/.'$global_markdown_extension'/.html/g')
	if [ "$edit_mode" != "yes" ]; then
		cat "$SRCFILE" > "$srcfile_unique_name"
	fi

    # Create the actual html page
    create_html_page "$srcfile_unique_name" "$htmlfile_unique_name" "no" "$title"
}

# Create html files from source files
# $1     the source file
# $2     the output file
# $3     "yes" if we want to generate the index.html,
#        "no" to insert new blog posts
# $4     title for the html header
# $5     optional original blog date
create_html_page() {
	html_content=$(get_srcfile_full_text "$1" | $global_markdown_cmd)
	#~ html_content=$(tail -n +2 "$1" | $global_markdown_cmd)
    html_output="$2"
    html_url="$output"
    html_index="$3"
    html_title="$4"
    html_timestamp="$5"
    if [ "$timestamp" == "" ]; then
		html_timestamp=$(modification_date "$1")
    fi
    
    generate_html_page "$html_content" "$html_url" "$html_index" "$html_title" "$html_timestamp" > "$html_output"
    touch -d "$html_timestamp" "$html_output"
}

# Generates page html content
# $1     html content
# $2     file url
# $3     "yes" if we want to generate the index.html,
#        "no" to insert new blog posts
# $4     title for the html header
# $5     blog date
generate_html_page() {
    page_content=$1
    page_url="$2"
    page_index="$3"
    page_title="$4"
    page_date="$5"
    
    single_post_header=""
    single_post_footer=""
    
    if [ "$page_index" == "no" ]; then
		page_formatted_date=$(formatted_date "$page_date" "$global_date_format")
		single_post_header="<h3><a class='ablack' href='$page_url'>$page_title</a></h3><div class='subtitle'>$page_formatted_date &mdash; $global_author</div>"
		single_post_footer="<div id='post_footer'><a href='$global_url'>$template_archive_index_page</a>"
		if [ "$global_disqus_shortname" != "" ]; then
			single_post_footer="$single_post_footer$(disqus)"
		fi
		single_post_footer="$single_post_footer </div>"
    fi
    
    html_header=$(create_html_header)
    html_footer=$(create_html_footer)
    html_title=$(create_html_title)
    html_google_analytics=$(google_analytics)
    
    cat << EOF
$html_header
<title>$page_title</title>
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
				$page_content
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
# $1      index [yes/NO]
# $2      archive [yes/NO]
# $3      entries [yes/NO]
# $4      rss [yes/NO]
# $5      css [yes/NO]
rebuild_all() {
	rebuild_index=$1
	rebuild_archive=$2
	rebuild_entries=$3
	rebuild_rss=$4
	rebuild_css=$5
	current_date=$(modification_date)
	
	if [ "$1" == "yes" ] || [ "$2" == "yes" ] || [ "$3" == "yes" ] || [ "$4" == "yes" ]; then
		counter=0
		index_content=""
		archive_content=""
		rss_content=""
		srcfile_lists=$(ls -t $global_post_directory*.$global_markdown_extension)
		for sourcefile in $srcfile_lists; do
			counter=$(( $counter + 1 ))
			echo -e "    $sourcefile"
			
			single_post_url=$(echo "$sourcefile" | sed "s/$global_markdown_extension\$/html/")
			single_post_title=$(get_srcfile_title "$sourcefile")
			single_post_date=$(modification_date "$sourcefile")
			single_post_formatted_date=$(formatted_date "$single_post_date" "$global_date_format")
			
			#~ Rebuild Index
			if [ "$1" == "yes" ]; then
				if [ "$counter" -le "$number_of_index_articles" ]; then
					index_single_post_header="<h3><a class='ablack' href='$single_post_url'>$single_post_title</a></h3><div class='subtitle'>$single_post_formatted_date &mdash; $global_author</div>"
					index_single_post_content=$(get_srcfile_short_text "$sourcefile" | $global_markdown_cmd)
					index_content="$index_content $index_single_post_header $index_single_post_content <div class='continue'><a href='$single_post_url'>$template_read_more</a></div>"
				fi
			fi
			
			#~ Rebuild archive
			if [ "$2" == "yes" ]; then
				archive_content="$archive_content <li><a href='$single_post_url'>$single_post_title</a> &mdash; $single_post_formatted_date</li>"
			fi
			
			#~ Rebuild entries
			if [ "$3" == "yes" ]; then
				index_single_post_content=$(get_srcfile_full_text "$sourcefile" | $global_markdown_cmd)
				generate_html_page "$index_single_post_content" "$single_post_url" "no" "$single_post_title" "$single_post_formatted_date" > "$single_post_url"
				chmod 644 "$single_post_url"
			fi
			
			#~ Rebuild RSS
			if [ "$4" == "yes" ]; then
				if [ "$counter" -le "$number_of_feed_articles" ]; then
					rss_single_post_content=$(get_srcfile_full_text "$sourcefile" | $global_markdown_cmd)
					rss_single_content="<item><title>$single_post_title</title>"
					rss_single_content="$rss_single_content <description><![CDATA[$rss_single_post_content]]></description>"
					rss_single_content="$rss_single_content <link>$global_url/$single_post_url</link>"
					rss_single_content="$rss_single_content <guid>$global_url/$single_post_url</guid>"
					rss_single_content="$rss_single_content <dc:creator>$global_author</dc:creator>"
					rss_single_content="$rss_single_content <pubDate>$single_post_date</pubDate></item>"
					rss_content="$rss_content $rss_single_content"
				fi
			fi
		done
    fi
    
    #~ Save Index
    if [ "$1" == "yes" ]; then
		if [ "$global_feedburner" == "" ]; then
			index_content="$index_content <div id='post_footer'><a href='$archive_index'>$template_archive ($counter)</a> &mdash; <a href='$blog_feed'>$template_subscribe</a></div>"
		else
			index_content="$index_content <div id='post_footer'><a href='$archive_index'>$template_archive</a> &mdash; <a href='$global_feedburner'>Subscribe</a></div>"
		fi
		generate_html_page "$index_content" "$single_post_url" "yes" "$global_title" "$current_date" > "$index_file"
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
		<lastBuildDate>$current_date</lastBuildDate>
		<pubDate>$current_date</pubDate>
		<atom:link href='$global_url$blog_feed' rel='self' type='application/rss+xml' />
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

# Rebuild blog content interactively
rebuild_interactive() {
	if [ "$1" == "" ]; then
		1="Rebuild the blog contents?"
	fi
	echo -n "$1"
	read rebuild_status
	if [ "$rebuild_status" != "n" ] && [ "$rebuild_status" != "N" ]; then
		echo "Rebuilding ... "
		rebuild_all "$2" "$3" "$4" "$5" "$6"
		echo "finished!"
	fi
}

# Create the css file from scratch
create_css() {
    # If the blog.css and main.css files do not exist, create them
    # Do not overwrite them though, to avoid smashing people's local changes
    if [ -f "blog.css" ]
    then
        echo "The file blog.css exists, not overwriting"
    else
        cat > "blog.css" << EOF
#title{font-size: x-large;}
a.ablack{color:black !important;}
li{margin-bottom:8px;}
ul,ol{margin-left:24px;margin-right:24px;}
#post_footer{margin-top:24px;text-align:center;}
.continue{margin:0px 12px;text-align:right;}
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
    fi
    if [ -f "main.css" ]
    then
        echo "The file main.css exists, not overwriting"
    else
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
    fi
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
        if [[ ! -x "$global_editor" ]]; then
			echo "Please set your \$EDITOR environment variable"
			exit
		fi
		EDITOR="$global_editor"
    fi
	
    # Check for validity of argument
    if [ "$1" != "rm" ] && [ "$1" != "init" ] && [ "$1" != "reset" ] && [ "$1" != "backup" ] && [ "$1" != "post" ] && [ "$1" != "rebuild" ] && [ "$1" != "list" ] && [ "$1" != "edit" ]; then 
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
    if [ "$1" == "rm" ]; then remove_entry "$2"; fi
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
