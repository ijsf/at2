unit SDL_events;

{  Automatically converted by H2PAS.EXE from SDL_events.h
   Utility made by Florian Klaempfl 25th-28th september 96
   Improvements made by Mark A. Malakanov 22nd-25th may 97 
   Further improvements by Michael Van Canneyt, April 1998 
   define handling and error recovery by Pierre Muller, June 1998 }

   { ***Edited by Daniel F Moisset, dmoisset@grulic.org.ar*** }

  interface

    uses SDL_types, SDL_syswm, SDL_keyboard;
  { C default packing is dword }

{$PACKRECORDS 4}

  {
      SDL - Simple DirectMedia Layer
      Copyright (C) 1997, 1998, 1999, 2000, 2001  Sam Lantinga
  
      This library is free software; you can redistribute it and/or
      modify it under the terms of the GNU Library General Public
      License as published by the Free Software Foundation; either
      version 2 of the License, or (at your option) any later version.
  
      This library is distributed in the hope that it will be useful,
      but WITHOUT ANY WARRANTY; without even the implied warranty of
      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
      Library General Public License for more details.
  
      You should have received a copy of the GNU Library General Public
      License along with this library; if not, write to the Free
      Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
  
      Sam Lantinga
      slouken@devolution.com
   }

  { Include file for SDL event handling  }


  const
  { Event enumerations  }
    SDL_NOEVENT=0;                      { Unused (do not remove) }
    SDL_EVENTACTIVE=1;                  { Application loses/gains visibility }
    SDL_KEYDOWN=2;                      { Keys pressed }
    SDL_KEYUP=3;                        { Keys released }
    SDL_MOUSEMOTION=4;                  { Mouse moved }
    SDL_MOUSEBUTTONDOWN=5;              { Mouse button pressed }
    SDL_MOUSEBUTTONUP=6;                { Mouse button released }
    SDL_JOYAXISMOTION=7;                { Joystick axis motion }
    SDL_JOYBALLMOTION=8;                { Joystick trackball motion }
    SDL_JOYHATMOTION=9;                 { Joystick hat position change }
    SDL_JOYBUTTONDOWN=10;               { Joystick button pressed }
    SDL_JOYBUTTONUP=11;                 { Joystick button released }
    SDL_EVENTQUIT=12;                   { User-requested quit }
    SDL_EVENTSYSWM=13;                  { System specific event }
    SDL_EVENT_RESERVEDA=14;             { Reserved for future use }
    SDL_EVENT_RESERVEDB=15;             { Reserved for future use }
    SDL_VIDEORESIZE=16;                 { User resized video mode }
    SDL_VIDEOEXPOSE=17;                 { Screen needs to be redrawn }
    SDL_EVENT_RESERVED2=18;             { Reserved for future use }
    SDL_EVENT_RESERVED3=19;             { Reserved for future use }
    SDL_EVENT_RESERVED4=20;             { Reserved for future use }
    SDL_EVENT_RESERVED5=21;             { Reserved for future use }
    SDL_EVENT_RESERVED6=22;             { Reserved for future use }
    SDL_EVENT_RESERVED7=23;             { Reserved for future use }
       { Events SDL_USEREVENT through SDL_MAXEVENTS-1 are for your use }
    SDL_EVENTUSER = 24;
       { This last event is only for bounding internal arrays
	  It is the number of bits in the event mask datatype -- Uint32
        }
    SDL_NUMEVENTS = 32;

  { Predefined event masks }
    SDL_ACTIVEEVENTMASK         = 1 shl (SDL_EVENTACTIVE);
    SDL_KEYDOWNMASK             = 1 shl (SDL_KEYDOWN);
    SDL_KEYUPMASK               = 1 shl (SDL_KEYUP);
    SDL_MOUSEMOTIONMASK         = 1 shl (SDL_MOUSEMOTION);
    SDL_MOUSEBUTTONDOWNMASK     = 1 shl (SDL_MOUSEBUTTONDOWN);
    SDL_MOUSEBUTTONUPMASK       = 1 shl (SDL_MOUSEBUTTONUP);
    SDL_MOUSEEVENTMASK          = SDL_MOUSEMOTIONMASK or 
                                  SDL_MOUSEBUTTONDOWNMASK or
                                  SDL_MOUSEBUTTONUPMASK;
    SDL_JOYAXISMOTIONMASK       = 1 shl (SDL_JOYAXISMOTION);
    SDL_JOYBALLMOTIONMASK       = 1 shl (SDL_JOYBALLMOTION);
    SDL_JOYHATMOTIONMASK        = 1 shl (SDL_JOYHATMOTION);
    SDL_JOYBUTTONDOWNMASK       = 1 shl (SDL_JOYBUTTONDOWN);
    SDL_JOYBUTTONUPMASK         = 1 shl (SDL_JOYBUTTONUP);
    SDL_JOYEVENTMASK            = SDL_JOYAXISMOTIONMASK or
                                  SDL_JOYBALLMOTIONMASK or
                                  SDL_JOYHATMOTIONMASK or
                                  SDL_JOYBUTTONDOWNMASK or
                                  SDL_JOYBUTTONUPMASK;
    SDL_VIDEORESIZEMASK         = 1 shl (SDL_VIDEORESIZE);
    SDL_VIDEOEXPOSEMASK         = 1 shl (SDL_VIDEOEXPOSE);
    SDL_QUITMASK                = 1 shl (SDL_EVENTQUIT);
    SDL_SYSWMEVENTMASK          = 1 shl (SDL_EVENTSYSWM);

    SDL_ALLEVENTS = $FFFFFFFF;

    type

    { Application visibility event structure  }
       SDL_ActiveEvent = record
            eventtype : Uint8; { SDL_ACTIVEEVENT }
            gain : Uint8;      { Whether given state were gained or lost (1/0) }
            state : Uint8;     { A mask of the focus states }
         end;

    { Keyboard event structure  }
       SDL_KeyboardEvent = record
            eventtype : Uint8;   { SDL_KEYDOWN or SDL_KEYUP }
            which : Uint8;       { The keyboard edvice index }
            state : Uint8;       { SDL_PRESSED or SDL_RELEASED }
            keysym : SDL_keysym;
         end;

    { Mouse motion event structure  }
       SDL_MouseMotionEvent = record
            eventtype : Uint8; { SDL_MOUSEMOTION }
            which : Uint8;     { The mouse device index }
            state : Uint8;     { The current button state }
            x, y : Uint16;     { The x/y coordinates of the mouse }
            xrel : Sint16;     { The relative motion in X direction }
            yrel : Sint16;     { The relative motion in Y  direction }
         end;

    { Mouse button event structure  }
       SDL_MouseButtonEvent = record
            eventtype : Uint8; { SDL_MOUSEBUTTONDOWN or SDL_MOUSEBUTTONUP }
            which : Uint8;     { The mouse device index }
            button : Uint8;    { The mouse button index }
            state : Uint8;     { SDL_PRESSED or SDL_RELEASED }
            x, y : Uint16;     { The X/Y coordinates of the mouse at press time }
         end;

    { Joystick axis motion event structure  }
       SDL_JoyAxisEvent = record
            eventtype : Uint8; { SDL_JOYAXISMOTION }
            which : Uint8;     { The joystick device index }
            axis : Uint8;      { The joystick axis index }
            value : Uint16;    { The axis value: (range: -32768 to 32768) }
         end;

    { Joystick trackball motion event structure  }
       SDL_JoyBallEvent = record
            eventtype : Uint8; { SDL_JOYBALLMOTION }
            which : Uint8;     { The joystick device index }
            ball : Uint8;      { The joystick trackball index }
            xrel : Uint16;     { The relative motion in X direction }
            yrel : Uint16;     { The relative motion in Y direction }
         end;

    { Joystick hat position change event structure  }
       SDL_JoyHatEvent = record
            eventtype : Uint8; { SDL_JOYHATMOTION }
            which : Uint8;     { The joystick device index }
            hat : Uint8;       { The joystick hat index }
            value : Uint16;    { The hat position value 
                                  8   1   2
                                  7   0   3
                                  6   5   4
			         Note that zero means the POV is centered.
                               }
         end;

    { Joystick button event structure  }
       SDL_JoyButtonEvent = record
            eventtype : Uint8; { SDL_JOYBUTTONDOWN or SDL_JOYBUTTONUP }
            which : Uint8;     { The joystick device index }
            button : Uint8;    { The joystick button index }
            state : Uint8;     { SDL_PRESSED or SDL_RELEASED }
         end;

    { The "window resized" event 
       When you get this event you are responsible for setting a new video
       mode with the new width and height.
    }
       SDL_ResizeEvent = record
            eventtype : Uint8; { SDL_VIDEORESIZE}
            w : Longint;       { New width }
            h : Longint;       { New height }
         end;

    { The "screen redraw" event }
       SDL_ExposeEvent = record
            eventtype : Uint8; { SDL_VIDEOEXPOSE }
         end;

    { The "quit requested" event }
       SDL_QuitEvent = record
            eventtype : Uint8; { SDL_QUIT }
         end;

    { A user defined event type }
       SDL_UserEvent = record
            eventtype : Uint8; { SDL_USEREVENT through SDL_NUMEVENTS-1 }
            code: Longint;     { User defined event code }
            data1: Pointer;    { User defined data pointer }
            data2: Pointer;    { User defined data pointer }
         end;

    { If you want to use this event, you should include SDL_syswm.h  }
       PSDL_SysWMmsg = ^SDL_SysWMmsg;
       SDL_SysWMEvent = record
            eventtype : Uint8;
            msg : PSDL_SysWMmsg;
         end;

    { General event structure  }
       PSDL_Event = ^SDL_Event;
       SDL_Event = record
           case longint of
              0 : ( eventtype : Uint8 );
              1 : ( active : SDL_ActiveEvent );
              2 : ( key : SDL_KeyboardEvent );
              3 : ( motion : SDL_MouseMotionEvent );
              4 : ( button : SDL_MouseButtonEvent );
              5 : ( jaxis : SDL_JoyAxisEvent );
              6 : ( jball : SDL_JoyBallEvent );
              7 : ( jhat : SDL_JoyHatEvent );
              8 : ( jbutton : SDL_JoyButtonEvent );
              9 : ( resize : SDL_ResizeEvent );
              10: ( expose : SDL_ExposeEvent );
              11: ( quit : SDL_QuitEvent );
              12: ( user : SDL_UserEvent );
              13: ( syswm : SDL_SysWMEvent );
           end;
    { Function prototypes  }
    { Pumps the event loop, gathering events from the input devices.
       This function updates the event queue and internal input device state.
       This should only be run in the thread that sets the video mode.
     }

    procedure SDL_PumpEvents;cdecl;

    { Checks the event queue for messages and optionally returns them.
       If 'action' is SDL_ADDEVENT, up to 'numevents' events will be added to
       the back of the event queue.
       If 'action' is SDL_PEEKEVENT, up to 'numevents' events at the front
       of the event queue, matching 'mask', will be returned and will not
       be removed from the queue.
       If 'action' is SDL_GETEVENT, up to 'numevents' events at the front 
       of the event queue, matching 'mask', will be returned and will be
       removed from the queue.
       This function returns the number of events actually stored, or -1
       if there was an error.  This function is thread-safe.
     }

    type

       SDL_eventaction =  Longint;
         Const
         SDL_ADDEVENT = 0;
         SDL_PEEKEVENT = 1;
         SDL_GETEVENT = 2;

    function SDL_PeepEvents(var events:SDL_Event; numevents:longint; action:SDL_eventaction; mask:Uint32):longint;cdecl;

    { Polls for currently pending events, and returns 1 if there are any pending
       events, or 0 if there are none available.  If 'event' is not nil, the next
       event is removed from the queue and stored in that area.
      }
    function SDL_PollEvent(event:pSDL_Event):longint;cdecl;

    { Waits indefinitely for the next available event, returning 1, or 0 if there
       was an error while waiting for events.  If 'event' is not nil, the next
       event is removed from the queue and stored in that area.
      }
    function SDL_WaitEvent(event:pSDL_Event):longint;cdecl;

    { Add an event to the event queue.
       This function returns 0, or -1 if the event couldn't be added to
       the event queue.  If the event queue is full, this function fails.
    }
    function SDL_PushEvent (var event: SDL_Event):longint;cdecl;
    
    {
      This function sets up a filter to process all events before they
      change internal state and are posted to the internal event queue.
    
      The filter is protypted as:
     }
    type
       SDL_EventFilter = function (event:pSDL_Event):longint;cdecl;
    {
      If the filter returns 1, then the event will be added to the internal queue.
      If it returns 0, then the event will be dropped from the queue, but the 
      internal state will still be updated.  This allows selective filtering of
      dynamically arriving events.
    
      WARNING:  Be very careful of what you do in the event filter function, as 
                it may run in a different thread!
    
      There is one caveat when dealing with the SDL_QUITEVENT event type.  The
      event filter is only called when the window manager desires to close the
      application window.  If the event filter returns 1, then the window will
      be closed, otherwise the window will remain open if possible.
      If the quit event is generated by an interrupt signal, it will bypass the
      internal queue and be delivered to the application at the next event poll.
     }

    procedure SDL_SetEventFilter(filter:SDL_EventFilter);cdecl;

    { Return the current event filter - can be used to "chain" filters.
      If there is no filter set, this function returns nil.
    }
    function SDL_GetEventFilter:SDL_EventFilter;cdecl;
    
    {
      This function allows you to set the state of processing certain events.
      If 'state' is set to SDL_IGNORE, that event will be automatically dropped
      from the event queue and will not event be filtered.
      If 'state' is set to SDL_ENABLE, that event will be processed normally.
      If 'state' is set to SDL_QUERY, SDL_EventState will return the 
      current processing state of the specified event.
     }

    const
       SDL_QUERY = -(1);
       SDL_IGNORE = 0;
       SDL_DISABLE = 0;
       SDL_ENABLE = 1;

    function SDL_EventState(eventtype:Uint8; state:longint):Uint8;cdecl;


  implementation

    procedure SDL_PumpEvents;cdecl;external 'SDL';

    function SDL_PeepEvents(var events:SDL_Event; numevents:longint; action:SDL_eventaction; mask:Uint32):longint;cdecl;external 'SDL';

    function SDL_PollEvent(event:pSDL_Event):longint;cdecl;external 'SDL';

    function SDL_WaitEvent(event:pSDL_Event):longint;cdecl;external 'SDL';

    function SDL_PushEvent (var event: SDL_Event):longint;cdecl;external 'SDL';

    procedure SDL_SetEventFilter(filter:SDL_EventFilter);cdecl;external 'SDL';

    function SDL_GetEventFilter:SDL_EventFilter;cdecl;external 'SDL';

    function SDL_EventState(eventtype:Uint8; state:longint):Uint8;cdecl;external 'SDL';

end.
