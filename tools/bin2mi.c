#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

int str2hex(char buf[]){
	int ans, num, cp, eflg, dt;
    ans = 0; cp = 0; eflg = 0;
    while(1){
    	dt = buf[cp++];
        if(dt>='0' && dt<='9') ans = ans * 16 + (dt-0x30);
        else
        if(dt>='A' && dt<='F') ans = ans * 16 + (dt-0x37);
        else break;
    }
    return ans;
}
int main(int argc,char *argv[])
{
	char buf[256];
	unsigned char c;
	int rmd,bc,bd;
	int adr, dt, hdt, bcnt;
	struct stat st;
	int dwiz;
	int mlen;
	
	if(argc<4) { 
		dwiz = 8; stat(argv[1], &st); mlen = st.st_size; 
	} else {
		dwiz = atoi(argv[3]);
		mlen = atoi(argv[4]);
	}
	
	FILE *fpr = fopen(argv[1], "rb");
    if(fpr==NULL) { printf("%s Not>Found\n",argv[1]); exit(1); }
    FILE *fpw = fopen(argv[2], "w");
	rmd = 0; bc = 0;
	
	fprintf(fpw,"#File_format=Hex\n");
	fprintf(fpw,"#Address_depth=%d\n", mlen);
	fprintf(fpw,"#Data_width=%d\n", dwiz);

	int i, rc;
	unsigned char d0,d1,d2,d3;
	for(i=0; i<mlen; i++){
		if(dwiz==8) {
		    rc = fread( buf,1,1,fpr); d0 = buf[0]; if(rc==0) d0 = 0;
			fprintf(fpw,"%02X\n", d0);
		} 
		else if(dwiz==16) { // For 68000
		    rc = fread( buf,1,1,fpr); d0 = buf[0]; if(rc==0) d0 = 0;
			rc = fread( buf,1,1,fpr); d1 = buf[0]; if(rc==0) d1 = 0;
			fprintf(fpw,"%02X%02X\n", d0, d1);
		} else {            // For 8086
		    rc = fread( buf,1,1,fpr); d0 = buf[0]; if(rc==0) d0 = 0;
			rc = fread( buf,1,1,fpr); d1 = buf[0]; if(rc==0) d1 = 0;
		    rc = fread( buf,1,1,fpr); d2 = buf[0]; if(rc==0) d2 = 0;
			rc = fread( buf,1,1,fpr); d3 = buf[0]; if(rc==0) d3 = 0;
			fprintf(fpw,"%02X%02X%02X%02X\n", d3, d2, d1,d0);
		}
	}
    fclose(fpr); fclose(fpw);
	return 0;
}
