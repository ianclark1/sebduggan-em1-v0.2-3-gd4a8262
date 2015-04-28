<!--- 
EM/1 - Extends the FW/1 framework with email templating.
Author:		Seb Duggan
			http://sebduggan.com
			seb@sebduggan.com
Version:	0.2

Copyright (c) 2010 Seb Duggan

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
--->

<cffunction name="sendEmail" access="public" returntype="any">
	<cfargument name="view" required="true" />
	<cfargument name="to" required="true" />
	<cfargument name="subject" default="" />
	
	<cfset var basepath = arguments.view />
	<cfset var viewpath = "" />
	<cfset var layoutpath = "" />
	<cfset var layout = "" />
	<cfset var arglayout = "" />
	<cfset var subsystem = "" />
	<cfset var body = "" />
	<cfset var type = "" />
	<cfset var attr = "" />
	<cfset var mailparts = structnew() />
	<cfset var mailattrs = structnew() />
	
	<!--- Get default mail attributes from framework setup --->
	<cfif structkeyexists(variables.framework, "emailDefaults")>
		<cfset mailattrs = duplicate(variables.framework.emailDefaults) />
	</cfif>
	
	<!--- Save argument set in arguments scope --->
	<cfif StructKeyExists(arguments, "layout")>
		<cfset arglayout = arguments.layout />
	<cfelse>
		<cfset layout = "default" />
	</cfif>
	
	<!--- Expand view path if full path not explicitly defined --->
	<cfif ListLen(arguments.view, "/") eq 1>
		<cfset basepath = getSection() & '/email/' & arguments.view />
	</cfif>
	
	<!--- Determine the view's subsystem --->
	<cfset subsystem = getSubsystem(basepath) />
	
	<!--- Process views and layouts --->
	<cfloop list="text,html" index="type">
		<cfset viewpath = parseViewOrLayoutPath(basepath & '.' & type, 'view') />
		
		<cfif fileexists(expandpath(viewpath))>
			<!--- Save mail content --->
			<cfsavecontent variable="body"><cfinclude template="#viewpath#" /></cfsavecontent>
			
			<!--- Override view-set layout with one specified in arguments --->
			<cfif len(arglayout)>
				<cfset layout = arglayout />
			</cfif>
			
			<!--- If a layout is specified, and the file exists, wrap the email in the layout --->
			<cfif len(layout) and not (isBoolean(layout) and layout is false)>
				<cfset layoutpath = parseViewOrLayoutPath(subsystem & variables.framework.subsystemDelimiter & '_email/' & layout & '.' & type, 'layout') />
				<cfif fileexists(expandpath(layoutpath))>
					<cfsavecontent variable="body"><cfinclude template="#layoutpath#" /></cfsavecontent>
				</cfif>
			</cfif>
			
			<!--- Add to the mailparts struct --->
			<cfset mailparts[type] = body />
			
			<!--- Set mail subject if it's been set in the view --->
			<cfset mailattrs.subject = subject />
		</cfif>
	</cfloop>
	
	<!--- If mailparts is empty struct, view has not been found, so throw an error --->
	<cfif structisempty(mailparts)>
		<cfset raiseException( type="FW1.emailViewNotFound", message="Unable to find email view '#basepath#'.",
				detail="Neither HTML nor plain text email template exists." ) />
	</cfif>
	
	<!--- Loop over any mail attributes in the arguments scope and add them into the mailattrs struct (overwrites defaults). --->
	<cfloop list="to,from,cc,bcc,subject,priority,replyto,failto" index="attr">
		<cfif StructKeyExists(arguments, attr) and len(arguments[attr])>
			<cfset mailattrs[attr] = arguments[attr] />
		</cfif>
	</cfloop>
	<cfif listlen(structkeylist(mailparts)) eq 1>
		<cfset mailattrs.type = structkeylist(mailparts) />
	</cfif>
	
	<!--- Send the email! --->
	<cfmail attributecollection="#mailattrs#"><cfif structkeyexists(mailattrs,"type")>#mailparts[mailattrs.type]#<cfelse>
		<cfloop list="text,html" index="type">
			<cfif StructKeyExists(mailparts,type)>
				<cfmailpart type="#type#">#mailparts[type]#</cfmailpart>
			</cfif>
		</cfloop>
	</cfif></cfmail>
</cffunction>
