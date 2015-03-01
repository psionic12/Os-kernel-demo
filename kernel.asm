%include	"pm.inc"
section .text
start:
bits 32
mov ax,10h
mov ds,ax
mov ss,ax
mov esp,systemStack
mov eax,100000h
add eax,tss0
mov [tss0Segment+2],ax
shr eax,16
mov [tss0Segment+4],al
mov [tss0Segment+7],ah
mov eax,100000h
add eax,tss1
mov [tss1Segment+2],ax
shr eax,16
mov [tss1Segment+4],al
mov [tss1Segment+7],ah
mov eax,100000h
add eax,ldt0
mov [ldt0Segment+2],ax
shr eax,16
mov [ldt0Segment+4],al
mov [ldt0Segment+7],ah
mov eax,100000h
add eax,ldt1
mov [ldt1Segment+2],ax
shr eax,16
mov [ldt1Segment+4],al
mov [ldt1Segment+7],ah
lgdt [gdtPtr]
lidt [idtPtr]
jmp 8:next
next:
init8259a:
mov	al, 011h
out	020h, al	; 主8259, ICW1.
nop
out	0A0h, al	; 从8259, ICW1.
nop
mov	al, 020h	; IRQ0 对应中断向量 0x20
out	021h, al	; 主8259, ICW2.
nop
mov	al, 028h	; IRQ8 对应中断向量 0x28
out	0A1h, al	; 从8259, ICW2.
nop
mov	al, 004h	; IR2 对应从8259
out	021h, al	; 主8259, ICW3.
nop
mov	al, 002h	; 对应主8259的 IR2
out	0A1h, al	; 从8259, ICW3.
nop
mov	al, 001h
out	021h, al	; 主8259, ICW4.
nop
out	0A1h, al	; 从8259, ICW4.
nop

mov	al, 11111110b	; 仅仅开启定时器中断
out	021h, al	; 主8259, OCW1.
nop
mov	al, 11111111b	; 屏蔽从8259所有中断
out	0A1h, al	; 从8259, OCW1.
nop
setIdt:
mov ebx,32*8+idt
mov word [ebx+2],codeSegment-gdt
mov eax,timeInterrupt
mov word [ebx],ax
shr eax,16
mov word [ebx+6],ax

mov al,byte [ebx+5]
add al,01100000b
mov byte [ebx+5],al

mov ebx,80*8+idt
mov word [ebx+2],codeSegment-gdt
mov eax,putchar
mov word [ebx],ax
shr eax,16
mov word [ebx+6],ax
mov al,byte [ebx+5]
add al,01100000b
mov byte [ebx+5],al



ring3:
mov ax,tss0Segment-gdt
ltr ax
mov ax,ldt0Segment-gdt
lldt ax
sti

push ldt0data-ldt0+7
push systemStack
push ldt0code-ldt0+7
push task0
retf

timeInterrupt:
mov al,20h
out 20h,al
mov ax,dataSegment-gdt
mov ds,ax
mov eax,1
cmp eax,[current]
je .1
mov [current],eax
jmp tss1Segment-gdt:0
jmp .2
.1:
mov byte [current],0
jmp tss0Segment-gdt:0
.2:
iret

putchar:
push bx
mov dx,3d4h
mov al,0eh
out dx,al
mov dx,3d5h
in al,dx
mov ah,al
mov dx,3d4h
mov al,0fh
out dx,al
mov dx,3d5h
in al,dx
cmp cl,0dh
jne .s1
cmp ax,0
jne .next
inc ax
.next:
mov bl,80
div bl
inc ax
mul bl
jmp setCursor
.s1:
cmp cl,0ah
jne .putchar
add ax,80
jmp roll
.putchar:
mov bx,videoSegment-gdt
mov es,bx
shl ax,1
mov bx,ax
mov [es:bx],cl
shr ax,1
inc ax
roll:
cmp ax,2000
jl setCursor
mov bx,videoSegment-gdt
mov es,bx
mov si,0a0h
mov di,0h
mov ecx,1920
.s:
mov eax,[es:si]
mov [es:di],eax
add si,2
add di,2
loop .s
mov bx,3840
mov cx,80
.cls:
mov word [es:bx],720h
add bx,2
loop .cls
mov ax,1920
setCursor:
mov bx,ax
mov dx,3d4h
mov al,0eh
out dx,al
mov dx,3d5h
mov al,bh
out dx,al
mov dx,3d4h
mov al,0fh
out dx,al
mov dx,3d5h
mov al,bl
out dx,al
pop bx
iret
cls:
push bx
mov ax,videoSegment-gdt
mov es,ax
mov ecx,80*25
mov bx,0
.s:
mov word [es:bx],700h
add bx,2
loop .s
mov ax,0
jmp setCursor
section .data 
align 8
gdt:			Descriptor       0,			0, 0
codeSegment:	Descriptor       100000h,			0ffffh, DA_C + DA_32
dataSegment:	Descriptor       100000h,			0ffffh,DA_DRW    
videoSegment:   Descriptor      0b8000h,			0ffffh, DA_DRW 
tss0Segment:	Descriptor     0,			103, DA_386TSS+DA_DPL3	
tss1Segment:   	Descriptor     0,			103, DA_386TSS+DA_DPL3	
ldt0Segment:	Descriptor     0,			67, DA_LDT
ldt1Segment:	Descriptor     0,			67, DA_LDT
gdtLen		equ	$ - gdt
times  128 dd 0
systemStack:
gdtPtr 	dw gdtLen-1
		dd gdt+100000h
current dd 0
align 8
idt:


%rep 80
	Gate 0,0,0,DA_386IGate
%endrep
	Gate 8,0,0,DA_386IGate
%rep 174
	Gate 0,0,0,0
%endrep
idtLen equ $-idt
idtPtr dw idtLen-1
	   dd idt+100000h

align 8
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ldt0:Descriptor       0,			0, 0
ldt0code:Descriptor       100000h,			0ffffh, DA_C + DA_32+DA_DPL3
ldt0data:Descriptor       100000h,			0ffffh,DA_DRW +DA_DPL3


tss0:
dd 0,tss0Stack,10h,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,ldt0Segment-gdt,8000000h
times 128 dd 0
tss0Stack:

ldt1:Descriptor       0,			0, 0
ldt1code:Descriptor       100000h,			0ffffh, DA_C + DA_32+DA_DPL3
ldt1data:Descriptor       100000h,			0ffffh,DA_DRW +DA_DPL3


tss1:
dd 0,tss1Stack,10h,0,0,0,0,0,task1,200h,0,0,0,0,usrStack1,0,0,0,17h,0fh,17h,17h,17h,017h,ldt1Segment-gdt,8000000h
times 128 dd 0
tss1Stack:

task0:
mov cl,'a'
int 80
mov ecx,1000000
.s:
loop .s
jmp task0
task1:
mov cl,'b'
int 80
mov ecx,1000000
.s:
loop .s
jmp task1
align 8
times 128 dd 0
usrStack1:
