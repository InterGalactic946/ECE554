//------------------------------------------------------------------------------
// grayscale_conv.sv
// Converts Bayer-pattern pixel stream to grayscale via interpolation.
// Uses a line buffer to access neighboring pixels and averages a 2x2 region.
// Outputs valid grayscale pixels on even row/column positions.
// Produces a grayscale pixel stream with corresponding data valid signal.
//------------------------------------------------------------------------------
module grayscale_conv (	
                oGray,
				oDVAL,
				iX_Cont,
				iY_Cont,
				iDATA,
				iDVAL,
				iCLK,
				iRST
				);

    input	[10:0]	iX_Cont;
    input	[10:0]	iY_Cont;
    input	[11:0]	iDATA;
    input			iDVAL;
    input			iCLK;
    input			iRST;

    output          oDVAL;
    output	[11:0]	oGray;

    ////////////////////////////////////////////////////////////////

    // Hold two elements from two rows at a time to perform interpolation
    wire	[11:0]	mDATA_0;
    wire	[11:0]	mDATA_1;
    reg		[11:0]	mDATAd_0;
    reg		[11:0]	mDATAd_1;

	// Grayscale data outputs.
    reg		[13:0]	mGray;
    reg				mDVAL;

	// Output the grayscale data.
    assign	oDVAL	=	mDVAL;
    assign  oGray   =   mGray[13:2];

	// Instantiate a Line Buffer to store a row of previous pixels.
    Line_Buffer1 	u0	(	.clken(iDVAL),
                            .clock(iCLK),
                            .shiftin(iDATA),
                            .taps0x(mDATA_1),
                            .taps1x(mDATA_0)	);

	// Convert input pixels to grayscale by interpolating the Bayer color pattern.
    always@(posedge iCLK or negedge iRST)
    begin
        if(!iRST)
        begin
            mGray	<=	0;
            mDATAd_0<=	0;
            mDATAd_1<=	0;
            mDVAL	<=	0;
        end
        else
        begin
            mDATAd_0	<=	mDATA_0;
            mDATAd_1	<=	mDATA_1;

			// Data is valid on every even row and even column (prevents overlap of data).
            mDVAL		<=	{iY_Cont[0]|iX_Cont[0]}	?	1'b0	:	iDVAL;

			// Average four neighboring pixels (in a sqaure shape) to get grayscale value.
            mGray       <= mDATA_0 + mDATAd_0 + mDATA_1 + mDATAd_1;
        end
    end 

endmodule
