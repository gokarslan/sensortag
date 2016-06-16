/*!
 *  \author         Kerim Gokarslan <kerimgokarslan@gmail.com>
 *  \brief          RSSI displayer for SensorTag2-Example iOS application
 *  \copyright      
 *  \file           rssiService.m
 */
/*
 * Copyright (c) 2015 Texas Instruments Incorporated
 *
 * All rights reserved not granted herein.
 * Limited License.
 *
 * Texas Instruments Incorporated grants a world-wide, royalty-free,
 * non-exclusive license under copyrights and patents it now or hereafter
 * owns or controls to make, have made, use, import, offer to sell and sell ("Utilize")
 * this software subject to the terms herein.  With respect to the foregoing patent
 *license, such license is granted  solely to the extent that any such patent is necessary
 * to Utilize the software alone.  The patent license shall not apply to any combinations which
 * include this software, other than combinations with devices manufactured by or for TI (“TI Devices”).
 * No hardware patent is licensed hereunder.
 *
 * Redistributions must preserve existing copyright notices and reproduce this license (including the
 * above copyright notice and the disclaimer and (if applicable) source code license limitations below)
 * in the documentation and/or other materials provided with the distribution
 *
 * Redistribution and use in binary form, without modification, are permitted provided that the following
 * conditions are met:
 *
 *   * No reverse engineering, decompilation, or disassembly of this software is permitted with respect to any
 *     software provided in binary form.
 *   * any redistribution and use are licensed by TI for use only with TI Devices.
 *   * Nothing shall obligate TI to provide you with source code for the software licensed and provided to you in object code.
 *
 * If software source code is provided to you, modification and redistribution of the source code are permitted
 * provided that the following conditions are met:
 *
 *   * any redistribution and use of the source code, including any resulting derivative works, are licensed by
 *     TI for use only with TI Devices.
 *   * any redistribution and use of any object code compiled from the source code and any resulting derivative
 *     works, are licensed by TI for use only with TI Devices.
 *
 * Neither the name of Texas Instruments Incorporated nor the names of its suppliers may be used to endorse or
 * promote products derived from this software without specific prior written permission.
 *
 * DISCLAIMER.
 *
 * THIS SOFTWARE IS PROVIDED BY TI AND TI’S LICENSORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
 * BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL TI AND TI’S LICENSORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>
#import "rssiService.h"
#import "sensorFunctions.h"
#import "masterUUIDList.h"
#import "masterMQTTResourceList.h"
#import <math.h>

@implementation rssiService

+(BOOL) isCorrectService:(CBService *)service {
    /*if ([service.UUID.UUIDString isEqualToString:TI_SENSORTAG_HUMIDTIY_SERVICE]) {
        return YES;
    }
    return NO;*/
    return YES;
}


-(instancetype) initWithService:(CBService *)service {
    self = [super initWithService:service];
    if (self) {
        self.btHandle = [bluetoothHandler sharedInstance];
        self.tile.origin = CGPointMake(4, 9);
        self.tile.size = CGSizeMake(4, 4);
        self.tile.title.text = @"RSSI";
        self.history = [NSMutableArray array];
        /*for(NSInteger i = 0;i<HISTORY_COUNT;++i){
            self.history[i] = [NSNumber numberWithInt:0];
        }*/
        self.lower = NSIntegerMin;
        self.upper = NSIntegerMax;
        self.historyIndex = 0;
    }
    return self;
}

-(BOOL) configureService {
    [super configureService];
    return YES;
}

-(BOOL) dataUpdate:(CBCharacteristic *)c {
    //if ([self.data isEqual:c]) {
        NSLog(@"RSSI: Recieved value : %@",c.value);
        oneValueCell *tile = (oneValueCell *)self.tile;
        //tile.value.numberOfLines = 2;
        tile.value.text = [NSString stringWithFormat:@"%@",[self calcValue:c.value]];
        return YES;
    //}
    return NO;
}

-(NSArray *) getCloudData {
    NSArray *ar = [[NSArray alloc]initWithObjects:
                   [NSDictionary dictionaryWithObjectsAndKeys:
                    //Value 1
                    [NSString stringWithFormat:@"%ld",(long)self.rssiNum.integerValue],@"value",
                    //Name 1
                    MQTT_RESOURCE_NAME_RSSI,@"name", nil],
                   [NSDictionary dictionaryWithObjectsAndKeys:
                                                           //Value 1
                                                           [NSString stringWithFormat:@"%lf",self.dist],@"value",
                                                           //Name 1
                                                           MQTT_RESOURCE_NAME_DISTANCE,@"name", nil], nil];
    return ar;
}

-(NSString *) calcValue:(NSData *) value {
    char scratchVal[value.length];
    [value getBytes:&scratchVal length:value.length];
    [self.btHandle.p readRSSI];
    self.rssiNum = self.btHandle.p.RSSI;
    //NSError* error;
    //self.btHandle.p. didReadRSSI:(NSNumber *)rssiNum error:(NSError *)error;
    //self.btHandle.p.rssi
    if(self.rssiNum != nil){
        self.history[self.historyIndex++]=self.rssiNum;
        if(self.historyIndex == HISTORY_COUNT){
            self.historyIndex = 0;
        }
    }
    double sumRssi = 0;
    for(NSInteger i = 0;i< [self.history count];++i){
        sumRssi += ((NSNumber*)self.history[i]).doubleValue;
    }
    self.dist = pow(10.0, (A-(sumRssi/HISTORY_COUNT))/(10 * N));
    return [NSString stringWithFormat:@"%d dBm (%lf m) ",self.rssiNum.intValue, self.dist];
}

@end
