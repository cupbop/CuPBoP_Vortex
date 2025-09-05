//========================================================================================================================================================================================================200
//	findRangeK function
//========================================================================================================================================================================================================200

__global__ void
findRangeK(	long height,

			knode *knodesD,
			long knodes_elem,

			long *currKnodeD,
			long *offsetD,
			long *lastKnodeD,
			long *offset_2D,
			int *startD,
			int *endD,
			int *RecstartD,
			int *ReclenD)
{

	// private thread IDs
	int thid = threadIdx.x;
	int bid = blockIdx.x;

	// ???

	//printf("currKnodeD[%d] = %ld, lastKnodeD[%d] = %ld\n", bid, currKnodeD[bid], bid, lastKnodeD[bid]);
	// if (thid == 0) {
	// 	printf("startD[%d] = %d, endD[%d] = %d\n", bid, startD[bid], bid, endD[bid]);
	// }

	int i;
	for(i = 0; i < height; i++){

		if((knodesD[currKnodeD[bid]].keys[thid] <= startD[bid]) && (knodesD[currKnodeD[bid]].keys[thid+1] > startD[bid])){
			//printf("knodesD[%ld].keys[%d] = %d, knodesD[%ld].keys[%d+1] = %d, startD[%d] = %d\n", currKnodeD[bid], thid, knodesD[currKnodeD[bid]].keys[thid], currKnodeD[bid], thid, knodesD[currKnodeD[bid]].keys[thid+1], bid, startD[bid]);
			// this conditional statement is inserted to avoid crush due to but in original code
			// "offset[bid]" calculated below that later addresses part of knodes goes outside of its bounds cause segmentation fault
			// more specifically, values saved into knodes->indices in the main function are out of bounds of knodes that they address
			if(knodesD[currKnodeD[bid]].indices[thid] < knodes_elem){
				offsetD[bid] = knodesD[currKnodeD[bid]].indices[thid];
				//printf("offsetD[%d] = %ld\n knodesD[%ld].indices[%d] = %d, bid = %d, knodes_elem = %ld\n", bid, offsetD[bid], currKnodeD[bid], thid, knodesD[currKnodeD[bid]].indices[thid], bid, knodes_elem);
			}
		}
		if((knodesD[lastKnodeD[bid]].keys[thid] <= endD[bid]) && (knodesD[lastKnodeD[bid]].keys[thid+1] > endD[bid])){
			// this conditional statement is inserted to avoid crush due to but in original code
			// "offset_2[bid]" calculated below that later addresses part of knodes goes outside of its bounds cause segmentation fault
			// more specifically, values saved into knodes->indices in the main function are out of bounds of knodes that they address
			if(knodesD[lastKnodeD[bid]].indices[thid] < knodes_elem){
				offset_2D[bid] = knodesD[lastKnodeD[bid]].indices[thid];
			}
		}
		__syncthreads();

		// set for next tree level
		if(thid==0){
			currKnodeD[bid] = offsetD[bid];
			lastKnodeD[bid] = offset_2D[bid];
		}
		__syncthreads();
	}

	// Find the index of the starting record
	if(knodesD[currKnodeD[bid]].keys[thid] == startD[bid]){
		RecstartD[bid] = knodesD[currKnodeD[bid]].indices[thid];
	}
	__syncthreads();

	// Find the index of the ending record
	if(knodesD[lastKnodeD[bid]].keys[thid] == endD[bid]){
		ReclenD[bid] = knodesD[lastKnodeD[bid]].indices[thid] - RecstartD[bid]+1;
	}

}

//========================================================================================================================================================================================================200
//	End
//========================================================================================================================================================================================================200
