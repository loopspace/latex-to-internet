module(...,package.seeall)

--[[
Whatsits follow catcodes:

1: Begining of group
2: End of group
3: Maths shift
7: Superscript
8: Subscript
   --]]

local types = {}
for k,v in pairs(node.types()) do
   types[v] = k
--   texio.write_nl(k .. ": " .. v)
end
types.ligature = 7

local whatsits = {}
for k,v in pairs(node.whatsits()) do
   whatsits[v] = k
--   texio.write_nl(k .. ": " .. v)
end

local factor = 65782  -- PDF points vs. TeX points
local txtfile
--local itex = require('itextomml')

local maths = {}
local domaths
local dolog

local function log(m,b)
   local dl
   if b == nil then
      dl = dolog
   else
      dl = b
   end
   if dl then
      texio.write_nl("term and log", m)
   end
end

local function utf8dec(a)
   log("Parsing utf8: " .. a)
   if a == 983040 then
--      return ""
   end
   if a == 8221 then
      a = 34
   elseif a == 8220 then
      a = 34
   elseif a == 8217 then
      a = 39
   end
    local t = {}
    if a < 128 then
        table.insert(t,a)
    elseif a < 2048 then
        local b,c
        b = a%64 + 128
        c = math.floor(a/64) + 192
        table.insert(t,c)
        table.insert(t,b)
    elseif a < 65536 then
        local b,c,d
        b = a%64 + 128
        c = math.floor(a/64)%64 + 128
        d = math.floor(a/4096) + 224
        table.insert(t,d)
        table.insert(t,c)
        table.insert(t,b)
    elseif a < 2097152 then
        local b,c,d,e
        b = a%64 + 128
        c = math.floor(a/64)%64 + 128
        d = math.floor(a/4096)%64 + 128
        e = math.floor(a/262144) + 240
        table.insert(t,e)
        table.insert(t,d)
        table.insert(t,c)
        table.insert(t,b)
    end
    local s = ""
    for k, v in ipairs(t) do
       s = s .. string.format("%x,", v)
    end
    log( string.char(table.unpack(t)) .. ":" ..  s )
    return string.char(table.unpack(t))
end


-- This function takes the table of single characters and find the
-- tags within it and puts them into single entries in the table
local function findtags(s)
   local a,t,p
   p = {}
   while s[1] do
      a = table.remove(s,1)
      if a == "<" then
	 t = {a}
	 -- tag, so slurp the whole lot
	 repeat
	    table.insert(t,table.remove(s,1))
	 until s[1] == ">"
	 table.insert(t,table.remove(s,1))
	 table.insert(p,table.concat(t))
      else
	 table.insert(p,a)
      end
   end
   return p
end

-- This function puts mn, mi, mo tags around anything that isn't
-- currently tagged
local function addtags(s)
   local a,t,p,tag,opts,j,ns,i,txt
   p = {}
   ns = #s
   i = 1
   while i <= ns do
      a = s[i]
      i = i + 1
      --      t = {a}
      if type(a) == "string" then
	 if a:sub(1,1) == "<" then
	    table.insert(p,a)
	    -- tag, check to see if mi,mo,mn,mtext
	    tag = a:match("%a+")
	    if tag == "mi" or tag == "mo" or tag == "mn" or tag == "mtext" then
	       local etag = "</" .. tag .. ">"
	       txt = ""
	       while s[i] and s[i] ~= etag do
		  txt = txt .. s[i]
		  i = i + 1
	       end
	       table.insert(p,txt)
	       table.insert(p,s[i])
	       i = i + 1
	    end
	 else
	    -- not a tag, needs wrapping in one
	    if a:match("%a") then
	       -- letter, so mi
	       table.insert(p,"<mi>")
	       table.insert(p,a)
	       table.insert(p,"</mi>")
	    elseif a:match("%d") then
	       -- number, get as much as looks like a number
	       table.insert(p,"<mn>")
	       table.insert(p,a)
	       while type(s[i]) == "string" and s[i]:match("%d") do
		  table.insert(p,s[i])
		  i = i + 1
	       end
	       if s[i] == "." then
		  table.insert(p,s[i])
		  i = i + 1
		  while type(s[i]) == "string" and s[i]:match("%d") do
		     table.insert(p,s[i])
		     i = i + 1
		  end
	       end		  
	       table.insert(p,"</mn>")
	    elseif a:match("%s") then
	       -- space, do nothing
	    else
	       -- other character
	       if a == "(" or a == ")" then
		  opts = " stretchy=\"false\""
	       else
		  opts = ""
	       end
	       table.insert(p,"<mo" .. opts .. ">")
	       table.insert(p,a)
	       table.insert(p,"</mo>")
	    end
	 end
      else
	 table.insert(p,a)
      end
   end
   return p
end

-- This function is a first attempt at ensuring that tags are
-- balanced, though it only currently fixes tags that were opened but
-- not closed
local function fixtags(s)
   local a,t,p,tag,ltag
   p = {}
   local stack = {}
   while s[1] do
      a = table.remove(s,1)
      if type(a) == "string" then
	 if a:sub(1,1) == "<" then
	    -- tag, need to get type
	    if a:sub(-2,-2) ~= "/" then
	       -- not an empty tag, so get tag name
	       tag = a:match("%a+")
	       if a:sub(2,2) == "/" then
		  -- close tag, check against stack and close all
		  -- necessary tags
		  ltag = table.remove(stack)
		  while ltag and ltag ~= tag do
		     table.insert(p,"</" .. ltag .. ">")
		     ltag = table.remove(stack)
		  end
	       else
		  -- open tag, add to stack
		  table.insert(stack,tag)
	       end
	    end
	 end
      end
      table.insert(p,a)
   end
   -- close any remaining tags
   ltag = table.remove(stack)
   while ltag and ltag ~= tag do
      table.insert(p,"</" .. ltag .. ">")
      ltag = table.remove(stack)
   end
   return p
end

-- Remove bare spaces
local function removespaces(s)
   local a,t,p
   p = {}
   while s[1] do
      a = table.remove(s,1)
      if type(a) == "string" and a:match("^%s+$") then
      else
	 table.insert(p,a)
      end
   end
   return p
end

local function parsemaths(s)
   -- sort out the tags
   log("Maths: " .. table.concat(s))
   s = findtags(s)
   s = addtags(s)
   s = fixtags(s)
   s = removespaces(s)
   local a,t,p,stack,ptag,ntag,pi,ni,i,m,tg,elt,ltg
   p = {}
   while s[1] do
      a = table.remove(s,1)
      if type(a) == "number" then
	 -- needs some post-processing
	 if a == 7 or a == 8 then
	    -- need to sort out the previous and next groups
	    -- first, find the previous group
	    i = #p
	    ptag = p[i]:match("%a+")
	    stack = 1
	    while i > 1 and stack > 0 do
	       i = i - 1
	       if type(p[i]) == "string" and p[i]:sub(1,1) == "<" then
		  -- got a tag
		  if p[i]:sub(-2,-2) ~= "/" then
		     -- not empty
		     if p[i]:sub(2,2) == "/" then
			-- closing tag, as we're going backwards add to stack
			stack = stack + 1
		     else
			-- opening tag
			stack = stack - 1
		     end
		  end
	       end
	    end
	    -- This is the position of the start of the previous tag
	    pi = i
	    -- log(pi .. " " .. ptag,true)
	    -- Now the same but forwards
	    i = 1
	    ntag = s[1]:match("%a+")
	    stack = 1
	    while i < #s and stack > 0 do
	       i = i + 1
	       if type(s[i]) == "string" and s[i]:sub(1,1) == "<" then
		  -- got a tag
		  if s[i]:sub(-2,-2) ~= "/" then
		     -- not empty
		     if s[i]:sub(2,2) == "/" then
			-- closing tag
			stack = stack - 1
		     else
			-- opening tag
			stack = stack + 1
		     end
		  end
	       end
	    end
	    -- This is the end of the next tag.
	    ni = i
	    -- log(ni .. " " .. ntag,true)
	    -- Basic idea is to put the start of the next tag outside
	    -- the previous group, but might need a little shifting
	    if ptag == 'msub' and ntag == 'msub' then
	       -- both are subscripts, so combine them
	       table.remove(p)
	       table.remove(s,1)
	    elseif ptag == 'msup' and 'ntag' == 'msup' then
	       -- both are superscripts, combine them
	       table.remove(p)
	       table.remove(s,1)
	    elseif ptag == 'msub' and ntag == 'msup' then
	       -- one of each, right way around
	       p[pi] = p[pi]:gsub(ptag,'msubsup',1)
	       s[ni] = s[ni]:gsub(ntag,'msubsup',1)
	       table.remove(p)
	       table.remove(s,1)
	    elseif ptag == 'msup' and ntag == 'msub' then
	       -- one of each, but wrong way around
	       p[pi] = p[pi]:gsub(ptag,'msubsup',1)
	       s[ni] = s[ni]:gsub(ntag,'msubsup',1)
	       table.remove(p)
	       table.remove(s,1)
	       tg = p[#p]:match("%a+")
	       tg = "<" .. tg
	       ltg = tg:len()
	       m = #p
	       for i=m,pi+1,-1 do
		  elt = table.remove(p)
		  table.insert(s,ni-1,elt)
		  if elt:sub(1,ltg) == tg then
		     break
		  end
	       end
	    else
	       -- Just need to put the previous tag inside the next one
	       table.insert(p,pi,table.remove(s,1))
	    end
	 elseif a == 1 then
	    table.insert(p,'<mrow>')
	 elseif a == 2 then
	    table.insert(p,'</mrow>')
	 end
      else
	 table.insert(p,a)
      end
   end
   return table.concat(p)
end


-- The argument must be a box (hbox or vbox)
local function list_elements(box)
   local parent = box
   local head = box --   = box.list or box
   while head do
      log("Element id: " .. head.id)
      if head.id == types.hlist or head.id == types.vlist then
	 -- it's a box, so we recurse into it
	 list_elements(head.list)
	 if head.id == 0 and parent.id == 1 then
	    -- We're an hbox inside a vbox, so must be finishing a line
	    if domaths then
	       table.insert(maths," ")
	    else
	       dooutput("\n")
	    end
	 end

      elseif head.id == types.glue then
	 -- some sort of space
--	 if parent.id == 0 then
	 -- only do something if in horizontal mode
	    if head.subtype == 13 then
	       -- glue, translate to space
	       if domaths then
		  table.insert(maths,string.rep(" ",math.floor(head.width/factor/5)))
	       else
		  dooutput(string.rep(" ",math.floor(head.width/factor/5)))
	       end
	    elseif head.subtype == 15 then
	       -- parfillskip, indicates new paragraph
	       -- dooutput("\n")
	    end
--	 end
      elseif head.id == types.glyph then
	 -- glyph, print its value
	 log("Char: " .. head.char)
	 if head.subtype%2 == 0 then
	    if domaths then
	       table.insert(maths,utf8dec(head.char))
	    else
	       dooutput(utf8dec(head.char))
	    end
	 end
      elseif head.id == types.ligature then
	 -- ligature, seems that subtype 2
	 if head.subtype == 2 then
	    if domaths then
	       table.insert(maths,"-")
	    else
	       dooutput("-")
	    end
	 end
      elseif head.id == types.whatsit then
	 -- whatsit, check if user defined
	 log("Subtype: " .. head.subtype)
	 if head.subtype == whatsits.user_defined then
	    if head.value == 3 then
	       -- maths shift
	       if domaths then
		  -- ending maths
		  domaths = false
		  dooutput(parsemaths(maths))
	       else
		  -- starting maths
		  domaths = true
		  maths = {}
	       end
	    elseif head.value == 7 or head.value == 8 or head.value == 1 or head.value == 2 then
	       if domaths then
		  table.insert(maths,head.value)
	       end
	    end
	 end
      else
	 log("Id: " .. head.id)
      end
      if not head.next then
	 -- last in list
      end
      -- next node in our list. If the list is at the end, head becomes nil and
      -- the loop ends.
      head = head.next
   end
   if box then
      if domaths then
	 table.insert(maths," ")
      else
	 dooutput("\n")
      end
   end
   return box
end

local function setlevel ()
   tex.attribute[1] = tex.currentgrouplevel
   return token.get_next()
end

function text_output()
   list_elements(tex.box[255])
end

-- Allows us to insert whatsits in the document as markers to be picked up later
function insert_whatsit(v)
   local w = node.new("whatsit","user_defined")
   w.type=100
   w.value=v
   node.write(w)
end

function do_nothing(h,t)
end

function initialise(s)
   s = s or "txt"
   local filename = tex.jobname .. '.' .. s
   txtfile = assert(io.open(filename,'w'))
   log("\nText output recorded in: " .. filename .. "\n",true)
   luatexbase.add_to_callback('pre_linebreak_filter', list_elements, 'Convert nodes to text')
--   luatexbase.add_to_callback('ligaturing', false, 'Disable ligatures')
--   luatexbase.add_to_callback('hyphenate', false, 'Disable hyphenation')
--   luatexbase.add_to_callback('kerning', false, 'Disable kerning')
   tex.attribute[1] = 0
end

function setlogging(b)
   if b == 1 then
      dolog = true
   else
      dolog = false
   end
end

function dooutput(m)
   --log(m,true)
   if m ~= "" then
      txtfile:write(m)
      txtfile:flush()
   end
end
