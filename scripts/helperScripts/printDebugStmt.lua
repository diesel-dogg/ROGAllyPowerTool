local printDebugStmt={}

local width=display.contentWidth
local height=display.contentHeight
local useOnScreenDebugging=false--can be tied to a UI button somewhere to control if on Screen debugging messages are to be shown
local blackScreen=nil--this will be the back underlay placed when on screen debugging is changed from off to on

local msgCounter=0
local displayObjects={}--text objects

function printDebugStmt.print(msg)
   --disable the debug statement functionality if the game is running on a device. The global boolean in main script that can also be used to force enable debugging messages
   if(system.getInfo("environment")~="device" or isDebugMode)then

         print(msg)--print to console

         if(useOnScreenDebugging)then--if on screen debugging is on, print messages on the screen
            displayObjects[#displayObjects+1]=display.newAutoSizeText({text=msg,x=350, y=100+msgCounter*80, width=700, align="left"})
            msgCounter=msgCounter+1
            if(msgCounter>15)then
               displayObjects[1]:removeSelf()--remove the first text if limit exceeded
               displayObjects[1]=nil
               table.remove(displayObjects,1)
               --shift all the remaining text objects upwards
               for i=1, #displayObjects do
                  displayObjects[i].y=displayObjects[i].y-80
               end
               msgCounter=msgCounter-1--decrement the counter
            end
         end
   end
end

--------------------------
function printDebugStmt.toggleOnScreenDebugging()
   --reset the message counter:
   msgCounter=0
   
   if (useOnScreenDebugging==false) then
      useOnScreenDebugging=true
      blackScreen=display.newRect(width/2,height/2, width, height)--add the black underlay
      blackScreen:setFillColor( 0,0,0,0.5 )
   elseif(useOnScreenDebugging==true) then
      useOnScreenDebugging=false

      local obj=display.remove(blackScreen)--rmove the black screen
      obj=nil

      for i= #displayObjects, 1, -1 do--remove all text objects
         local obj=display.remove(displayObjects[i])
         table.remove( displayObjects,i )
         obj=nil
      end
   end
end
------------------------

--printing of debugStmts to screen is off by default. Toggle it so that the default settings becomes ON
-- printDebugStmt.toggleOnScreenDebugging()

return printDebugStmt