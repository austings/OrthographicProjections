//Author Austin Sierra
//Last Change July 21, 2023 
//for Church of AI Christ
//Subject to Creative Commons BY-NC 4.0

Cd(__DIR__);;

#include "Tensor3D.HC";
//#include "TileSet.HC";

#define SCREENX 640
#define SCREENY 480

#define MAP_SCALE 8
#define MICRO_STEPS 4

#define FLOOR 0
#define NORTH 1
#define EAST 2
#define SOUTH 3
#define WEST 4
#define TOP 5

#define EMPTY 0
#define SANDWALL 1
#define SANDFLOOR 2

#define LVLSIZE 14
#define FACES 6

U8 tileSize = 32;//pixels

class Wall
{
  CSpriteColor	color;
  CSpritePtPt	line1;
  CSpritePtPt	line2;
  CSpritePtPt	line3;
  CSpritePtPt   line4;
  CSpritePt	fill;
  CSpriteBase	end;
};

public class Quad
{
   Vector *q1, *q2, *q3, *q4;
};

Vector *levelSize = CreateVector(3);  
SetVector(levelSize,LVLSIZE,0);
SetVector(levelSize,LVLSIZE,1);
SetVector(levelSize,FACES,2);

Tensor3D *level1 = CreateTensor(levelSize);

public class Camera
{
  Vector *pos;
  F64 angle,value;//left right
  F64 pitch,pvalue;//up down
  F64 zoom;
};
Camera *cam = MAlloc(sizeof(Camera));
Vector *cameraStart = CreateVector(3);

public class Keys
{
  Bool space,left,right,up,down,lmouse,rmouse;
  F64 mx,my;
};
Keys keys;


U0 Init(CDC *dc)
{
 I64 i,x,y;
 QueInit(&keys);
 DocClear;
 
 DCDel(dc);
}

U0 SetBounds(Tensor3D *world)
{
  Vector *tShape = world->shape;
  I64 i=0,j=0,
    x = GetVector(tShape,0),
    y = GetVector(tShape,1);
  
  for(i=0;i<x;i++)
  {
   for(j=0;j<y;j++)
   {
    SetTensor(world,SANDFLOOR,i,j,0);
   }
  }
  
  for(i=0;i<x;i++)
  {
   SetTensor(world,SANDWALL,i,0,1);
  }

  for(i=0;i<y;i++)
  {
   SetTensor(world,SANDWALL,0,i,4);
  }

  for(i=0;i<x;i++)
  {
   SetTensor(world,SANDWALL,i,x-1,3);
  }

  for(i=0;i<y;i++)
  {
   SetTensor(world,SANDWALL,y-1,i,2);
  }
}

U0 DrawSq(CDC *dc, Quad *toDraw)
{
  CD3I32 poly[4];
  poly[0].x=GetVector(toDraw->q1,0);
  poly[0].y=GetVector(toDraw->q1,1);
  poly[0].z=GetVector(toDraw->q1,2);

  poly[1].x=GetVector(toDraw->q2,0);
  poly[1].y=GetVector(toDraw->q2,1);
  poly[1].z=GetVector(toDraw->q2,2);

  poly[2].x=GetVector(toDraw->q3,0);
  poly[2].y=GetVector(toDraw->q3,1);
  poly[2].z=GetVector(toDraw->q3,2);

  poly[3].x=GetVector(toDraw->q4,0);
  poly[3].y=GetVector(toDraw->q4,1);
  poly[3].z=GetVector(toDraw->q4,2);
  GrFillPoly3(dc,4,poly);

}

/*
Quad MPDraw(CTask *task)
{
  //dc->flags|=DCF_TRANSFORMATION;
   Quad *floor = MAlloc(sizeof(Quad)); 
   floor->q0 = GetMatrixVector(faces,4);
   floor->q1 = GetMatrixVector(faces,0);
   floor->q2 = GetMatrixVector(faces,1);
   floor->q3 = GetMatrixVector(faces,5);
   //quads[0] = floor;
   return floor;


}
*/

Matrix *CreateCell(Vector *cellCoord, Vector *camCoord,
  F64 cAngle,F64 cPitch, F64 cZoom)
{
  I64 i;
  F64 curr,s,c;
  Matrix *unitCube = CreateMatrix(8,3);

  SetMatrix(unitCube,0+(GetVector(cellCoord,0)*32)+GetVector(cam->pos,0),0,0);
  SetMatrix(unitCube,32+(GetVector(cellCoord,1)*32)+GetVector(cam->pos,1),0,1);
  SetMatrix(unitCube,0,0,2);

  SetMatrix(unitCube,32+(GetVector(cellCoord,0)*32)+GetVector(cam->pos,0),1,0);
  SetMatrix(unitCube,32+(GetVector(cellCoord,0)*32)+GetVector(cam->pos,1),1,1);
  SetMatrix(unitCube,0,1,2);

  SetMatrix(unitCube,32+(GetVector(cellCoord,0)*32)+GetVector(cam->pos,0),2,0);
  SetMatrix(unitCube,0+(GetVector(cellCoord,1)*32)+GetVector(cam->pos,1),2,1);
  SetMatrix(unitCube,0,2,2);

  SetMatrix(unitCube,0+(GetVector(cellCoord,0)*32)+GetVector(cam->pos,0),3,0);
  SetMatrix(unitCube,0+(GetVector(cellCoord,1)*32)+GetVector(cam->pos,1),3,1);
  SetMatrix(unitCube,0,3,2);
  
  SetMatrix(unitCube,0+(GetVector(cellCoord,0)*32)+GetVector(cam->pos,0),4,0);
  SetMatrix(unitCube,32+(GetVector(cellCoord,1)*32)+GetVector(cam->pos,1),4,1);
  SetMatrix(unitCube,-32,4,2); 

  SetMatrix(unitCube,32+(GetVector(cellCoord,0)*32)+GetVector(cam->pos,0),5,0);
  SetMatrix(unitCube,32+(GetVector(cellCoord,1)*32)+GetVector(cam->pos,1),5,1);
  SetMatrix(unitCube,-32,5,2);

  SetMatrix(unitCube,32+(GetVector(cellCoord,0)*32)+GetVector(cam->pos,0),6,0);
  SetMatrix(unitCube,0+(GetVector(cellCoord,1)*32)+GetVector(cam->pos,1),6,1);
  SetMatrix(unitCube,-32,6,2);

  SetMatrix(unitCube,0+(GetVector(cellCoord,0)*32)+GetVector(cam->pos,0),7,0);
  SetMatrix(unitCube,0+(GetVector(cellCoord,1)*32)+GetVector(cam->pos,1),7,1);
  SetMatrix(unitCube,-32,7,2);

  return unitCube;
     
}

Quad **GetQuadFaces(Vector *cellCoord, Vector *camCoord,
  F64 cAngle,F64 cPitch, F64 cZoom)
{
   I64 **quads=MAlloc(6*sizeof(Quad));
   
   Matrix *faces = CreateCell(cellCoord,camCoord,cAngle,cPitch,cZoom);
      

   Quad *floor = MAlloc(sizeof(Quad)); 
   floor->q1 = GetMatrixVector(faces,4);
   floor->q2 = GetMatrixVector(faces,0);
   floor->q3 = GetMatrixVector(faces,1);
   floor->q4 = GetMatrixVector(faces,5);
   quads[0] = floor;

   Quad *north = MAlloc(sizeof(Quad));
   north->q1 = GetMatrixVector(faces,6);
   north->q2 = GetMatrixVector(faces,5);
   north->q3 = GetMatrixVector(faces,4);
   north->q4 = GetMatrixVector(faces,7);
   quads[1] = north;
   //red
   Quad *south = MAlloc(sizeof(Quad));
   south->q1 = GetMatrixVector(faces,3);
   south->q2 = GetMatrixVector(faces,0);
   south->q3 = GetMatrixVector(faces,1);
   south->q4 = GetMatrixVector(faces,2);
   quads[2] = south;

   //blue
   Quad *east = MAlloc(sizeof(Quad));
   east->q1 = GetMatrixVector(faces,7);
   east->q2 = GetMatrixVector(faces,4);
   east->q3 = GetMatrixVector(faces,0);
   east->q4 = GetMatrixVector(faces,3);
   quads[3] = east;

   //black
   Quad *west = MAlloc(sizeof(Quad));
   west->q1 = GetMatrixVector(faces,2);
   west->q2 = GetMatrixVector(faces,1);
   west->q3 = GetMatrixVector(faces,5);
   west->q4 = GetMatrixVector(faces,6);
   quads[4] = west;
   
   //green
   Quad *top = MAlloc(sizeof(Quad));
   top->q1 = GetMatrixVector(faces,7);
   top->q2 = GetMatrixVector(faces,3);
   top->q3 = GetMatrixVector(faces,2);
   top->q4 = GetMatrixVector(faces,6);
   quads[5] = top;

  DestroyMatrix(faces);
   Free(floor);
   Free(north);
   Free(south);
   Free(east);
   Free(west);
   Free(top); 
   return quads;
}

//public U0 Sprite3ZB(CDC *dc=gr.dc,I64 x,I64 y,I64 z,U8 *elems,F64 e=0)
//{//Plot rotated around X,Z axis.
//  I64 r[16];
//  Mat4x4IdentEqu(r);
//  Mat4x4RotZ(r,e);
//  Sprite3Mat4x4B(dc,x,y,z,elems,r);
//}

U0 DrawIt(CTask *task, CDC *dc)
{
  
  dc->flags|=DCF_TRANSFORMATION;
  cam->angle=ã/2.0*cam->value;
  cam->pitch=ã/2.0*cam->pvalue;
  Mat4x4RotZ(dc->r,cam->angle);
  Mat4x4RotY(dc->r,cam->pitch);

  I64 i, j, k, 
   objpos,cursor_x,cursor_y,count=0;
  F64 dividX;
  F64 dividY;
  
  if(keys.left)
  {
    
    keys.left=FALSE;
    cam->value=cam->value+.1;
  }
  if(keys.right)
  {
    
    keys.right=FALSE;
    cam->value=cam->value-.1;
  }  
  if(keys.up)
  {
    keys.up=FALSE;
    cam->pvalue=cam->pvalue-.1;
  }
  if(keys.down)
  {
    keys.down=FALSE;
    cam->pvalue=cam->pvalue+.1;
  }
  if(keys.lmouse)
  {
    cursor_x=ms.pos.x-keys.mx;//+cx-parent->pix_left-parent->scroll_x;
    cursor_y=ms.pos.y-keys.my;//+cy-parent->pix_top -parent->scroll_y;
    SetVector(cam->pos,GetVector(cam->pos,0)+cursor_x,0);
    SetVector(cam->pos,GetVector(cam->pos,1)+cursor_y,1);
    keys.mx=ms.pos.x;
    keys.my=ms.pos.y;
    
  }
  if(keys.rmouse)
  {
    cursor_x=ms.pos.x;
    cursor_y=ms.pos.y;
  }
  
  //DCDepthBufAlloc(dc);
  for(i=0;i<LVLSIZE;i++)
  {
    for(j=0;j<LVLSIZE;j++)
    {
      dividX = SCREENX/(i+1);
      dividY = SCREENY/(j+1);
      Vector *cellCoord = CreateVector(2);
      SetVector(cellCoord,i,0);
      SetVector(cellCoord,j,1);
      Vector *camCoord =   cam->pos;
      //Qtest;
      Quad **toDraw = GetQuadFaces(cellCoord,
           camCoord,cam->angle,cam->pitch,cam->zoom);
      for(k=0;k<6;k++)
      {
        //PrintVector(toDraw[k]->q1);
        count++;
        I64 texture = GetTensor(level1,i,j,k);
        U8 sprite = 0;//GetTile(texture);
        if(texture!=0&&texture!=2)//empty or floor
        {
         if(k==0)
          dc->color=YELLOW;
         if(k==1)
          dc->color=BLACK;
         if(k==2)
          dc->color=RED;
         if(k==3)
          dc->color=BLUE;
         if(k==4)
          dc->color=PURPLE;
         if(k==5)
          dc->color=GREEN;
         try{
           DrawSq(dc,toDraw[k]);
         }catch
         {GrPrint(dc,50,FONT_HEIGHT,"MAP ERROR");}
         //TiltedWall(toDraw[k], drawnSprites[count]);
         //Sprite3ZB(dc,i*dividX,j*dividY,0,sprite,50);
        }
        else
        { 
          if(texture==2)
          {
            dc->color=YELLOW;
            DrawSq(dc,toDraw[k]);
          }
        }
               
      }
      DestroyVector(cellCoord);
   }
 }
}

U0 CleanUp()
{
   PutExcept;
   DocClear;
   SettingsPop;
   MenuPop;
   GetChar;
   Free(cam);
   DestroyTensor(level1);
   DestroyVector(cameraStart);
}

U0 StraitsRun()
{
  I64 arg1,arg2;
  CDC *dc=DCAlias;
  SettingsPush;
  WinMax;
  DocCursor;
  DocClear;
  SetVector(cameraStart,0,0);
  SetVector(cameraStart,0,1);
  SetVector(cameraStart,0,2);
  cam->pos = cameraStart;
  cam->angle = 0.0;
  cam->value = 0.0;
  cam->pitch = 5.5;
  cam->zoom  = 0.0;
  keys.lmouse=FALSE;
  keys.rmouse=FALSE;  

  SetBounds(level1);  

  Fs->draw_it=&DrawIt;

  try{
    while(TRUE) {
         
     switch (GetMsg(&arg1,&arg2,1<<MSG_KEY_DOWN|1<<MSG_MS_L_DOWN|
	    1<<MSG_MS_R_DOWN|1<<MSG_MS_R_UP|1<<MSG_MS_MOVE|1<<MSG_MS_L_UP)) {

        case MSG_KEY_UP:
          case 0:
          switch(arg2.u8[0])
          {
            case SC_CURSOR_LEFT:
             keys.left=TRUE;
             break;
            case SC_CURSOR_RIGHT:
             keys.right=TRUE;
             break;
            case SC_CURSOR_UP:
             keys.up=TRUE;
             break;
            case SC_CURSOR_DOWN:
             keys.down=TRUE;
             break;
          }
          break;
        case MSG_KEY_DOWN:
          switch(arg1)
          {
           case CH_ESC:
           case CH_SHIFT_ESC:
            goto fs_done;
            break;
           case 0:
            switch(arg2.u8[0])
            {
              case SC_CURSOR_LEFT:
               keys.left=TRUE;
               break;
              case SC_CURSOR_RIGHT:
               keys.right=TRUE;
               break;
              case SC_CURSOR_UP:
               keys.up=TRUE;
               break;
              case SC_CURSOR_DOWN:
               keys.down=TRUE;
               break;
            }
            break;
          }
          break;
        case MSG_MS_L_DOWN:
          //GrPrint(dc,50,FONT_HEIGHT,"DOWN");
          keys.mx = arg1;
          keys.my = arg2;
          keys.lmouse=TRUE;
          break;
        case MSG_MS_L_UP:
          keys.lmouse=FALSE;
          //GrPrint(dc,50,FONT_HEIGHT,"UP");
          break;
        case MSG_MS_R_DOWN:
          keys.mx = arg1;
          keys.my = arg2;
          keys.rmouse=TRUE;
          break;
        //case MSG_MS_R_UP:
        //  keys.rmouse=FALSE;
        //  break;
        case '\n':
          Init(dc);
          break;
      }
    }
  fs_done:
  }
  catch{
    CleanUp();
    DCDel(dc);
  }
  //CleanUp(dc);
}
StraitsRun;