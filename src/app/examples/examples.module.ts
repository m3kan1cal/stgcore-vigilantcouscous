import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AngularMultiSelectModule } from 'angular2-multiselect-dropdown';
import { FormsModule } from '@angular/forms';
import { TagInputModule } from 'ngx-chips';
import { NouisliderModule } from 'ng2-nouislider';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';
import { JwBootstrapSwitchNg2Module } from 'jw-bootstrap-switch-ng2';
import { AgmCoreModule } from '@agm/core';
import { RouterModule } from '@angular/router';

import { ExamplesComponent } from './examples.component';
import { MethodologyComponent } from './methodology/methodology.component';
import { ServicesComponent } from './services/services.component';

import { LandingComponent } from './landing/landing.component';

@NgModule({
    imports: [
        CommonModule,
        FormsModule,
        NgbModule,
        TagInputModule,
        NouisliderModule,
        JwBootstrapSwitchNg2Module,
        AngularMultiSelectModule,
        AgmCoreModule.forRoot({
            apiKey: 'NO_API_KEY'
        }),
        RouterModule
    ],
    declarations: [
        ExamplesComponent,
        MethodologyComponent,
        ServicesComponent,
        LandingComponent
    ]
})
export class ExamplesModule { }
